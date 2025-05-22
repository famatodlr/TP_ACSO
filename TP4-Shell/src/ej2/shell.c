#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <string.h>

#define MAX_COMMANDS 200

int is_exit_command(const char *cmd) {
    return strcmp(cmd, "exit") == 0 || strcmp(cmd, "q") == 0;
}

char **parse_args(char *command) {
    char **args = malloc(100 * sizeof(char*));
    int i = 0;
    char *p = command;

    while (*p) {
        while (*p == ' ') p++; // saltar espacios

        if (*p == '\0') break;

        if (*p == '"') {
            p++;
            char *start = p;
            while (*p && *p != '"') p++;
            int len = p - start;
            args[i] = malloc(len + 1);
            strncpy(args[i], start, len);
            args[i][len] = '\0';
            if (*p == '"') p++; // saltar la comilla de cierre
        } else {
            char *start = p;
            while (*p && *p != ' ') p++;
            int len = p - start;
            args[i] = malloc(len + 1);
            strncpy(args[i], start, len);
            args[i][len] = '\0';
        }
        i++;
    }
    args[i] = NULL;
    return args;
}

int main() {
    char command[256];
    char *commands[MAX_COMMANDS];

    while (1) {
        printf("Shell> ");
        fflush(stdout);

        if (!fgets(command, sizeof(command), stdin)) break;
        command[strcspn(command, "\n")] = '\0';

        if (is_exit_command(command)) break;

        int command_count = 0;
        char *token = strtok(command, "|");
        while (token != NULL) {
            commands[command_count++] = token;
            token = strtok(NULL, "|");
        }

        int pipes[command_count - 1][2];
        for (int i = 0; i < command_count - 1; i++) {
            if (pipe(pipes[i]) == -1) {
                perror("pipe");
                exit(1);
            }
        }

        for (int i = 0; i < command_count; i++) {
            pid_t pid = fork();
            if (pid == -1) {
                perror("fork");
                exit(1);
            }

            if (pid == 0) {
                if (i > 0) dup2(pipes[i - 1][0], STDIN_FILENO);
                if (i < command_count - 1) dup2(pipes[i][1], STDOUT_FILENO);

                for (int j = 0; j < command_count - 1; j++) {
                    close(pipes[j][0]);
                    close(pipes[j][1]);
                }

                char **args = parse_args(commands[i]);
                execvp(args[0], args);
                perror("execvp");
                exit(1);
            }
        }

        for (int i = 0; i < command_count - 1; i++) {
            close(pipes[i][0]);
            close(pipes[i][1]);
        }

        for (int i = 0; i < command_count; i++) {
            wait(NULL);
        }
    }

    return 0;
}
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr, "Uso: anillo <n> <c> <s>\n");
        exit(1);
    }

    int n = atoi(argv[1]);
    int val = atoi(argv[2]);
    int start = atoi(argv[3]);

    if (n <= 0) {
        fprintf(stderr, "Error: la cantidad de procesos debe ser mayor a 0.\n");
        exit(1);
    }

    if (val < 0) {
        fprintf(stderr, "Error: el valor inicial debe ser no negativo.\n");
        exit(1);
    }

    if (start < 0 || start >= n) {
        fprintf(stderr, "Error: el proceso inicial debe estar entre 0 y %d.\n", n - 1);
        exit(1);
    }

    int pipes[n][2];

    for (int i = 0; i < n; i++) {
        if (pipe(pipes[i]) == -1) exit(1);
    }

    for (int i = 0; i < n; i++) {
        if (fork() == 0) {
            for (int j = 0; j < n; j++) {
                if (j != i) close(pipes[j][0]);
                if (j != (i + 1) % n) close(pipes[j][1]);
            }

            int x;

            if (i == start) {
                x = val;
                printf("Proceso %d recibió %d\n", i, x);
                x++;
                write(pipes[(i + 1) % n][1], &x, sizeof(int));
                read(pipes[i][0], &x, sizeof(int));
                printf("Resultado final recibido por el proceso %d: %d\n", i, x);
            } else {
                read(pipes[i][0], &x, sizeof(int));
                printf("Proceso %d recibió %d\n", i, x);
                x++;
                write(pipes[(i + 1) % n][1], &x, sizeof(int));
            }

            close(pipes[i][0]);
            close(pipes[(i + 1) % n][1]);
            exit(0);
        }
    }

    for (int i = 0; i < n; i++) {
        close(pipes[i][0]);
        close(pipes[i][1]);
    }

    for (int i = 0; i < n; i++) wait(NULL);
    return 0;
}
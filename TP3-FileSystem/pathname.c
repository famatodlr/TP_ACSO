#include <string.h>
#include <stdio.h>
#include "pathname.h"
#include "directory.h"
#include "inode.h"

#define ROOT_INODE_NUMBER 1

int pathname_lookup(struct unixfilesystem *fs, const char *pathname) {
    if (pathname == NULL || strlen(pathname) == 0) {
        fprintf(stderr, "Path vacío o nulo\n");
        return -1;
    }

    char path_copy[1024];
    strncpy(path_copy, pathname, sizeof(path_copy));
    path_copy[sizeof(path_copy) - 1] = '\0';

    int current_inumber = ROOT_INODE_NUMBER;
    char *token = strtok(path_copy, "/");

    while (token != NULL) {
        struct direntv6 dir_entry;

        fprintf(stderr, "Buscando '%s' en inodo %d\n", token, current_inumber);

        if (directory_findname(fs, token, current_inumber, &dir_entry) < 0) {
            fprintf(stderr, "No se encontró el componente '%s' en inodo %d\n", token, current_inumber);
            return -1;
        }

        current_inumber = dir_entry.d_inumber;
        token = strtok(NULL, "/");
    }

    return current_inumber;
}
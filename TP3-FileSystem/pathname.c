#include <string.h>
#include <stdio.h>
#include "pathname.h"
#include "directory.h"
#include "inode.h"

#define ROOT_INODE_NUMBER 1

int pathname_lookup(struct unixfilesystem *fs, const char *pathname) {
    if (pathname == NULL || fs == NULL) return -1;

    // Si el path es "/", devolvemos el inodo raíz
    if (strcmp(pathname, "/") == 0) {
        return ROOT_INODE_NUMBER;
    }

    char pathcopy[strlen(pathname) + 1];
    strcpy(pathcopy, pathname);

    int curr_inumber = ROOT_INODE_NUMBER;

    // Nos saltamos el primer '/' si lo hay
    char *token = strtok(pathcopy, "/");
    while (token != NULL) {
        struct direntv6 dirEnt;
        if (directory_findname(fs, token, curr_inumber, &dirEnt) != 0) {
            return -1; // No se encontró un componente del path
        }

        curr_inumber = dirEnt.d_inumber;
        token = strtok(NULL, "/");
    }

    return curr_inumber;
}
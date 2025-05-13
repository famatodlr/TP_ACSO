#include "pathname.h"
#include "directory.h"
#include "inode.h"
#include "diskimg.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

/**
 * Busca el número de inodo asociado a un pathname.
 * Devuelve el inumber correspondiente si lo encuentra, o -1 en caso de error.
 */
int pathname_lookup(struct unixfilesystem *fs, const char *pathname) {
    if (!pathname || pathname[0] != '/') {
        return -1;
    }

    int current_inode = 1;

    char temp_path[256];
    strncpy(temp_path, pathname, sizeof(temp_path));
    temp_path[sizeof(temp_path) - 1] = '\0';

    char *component = strtok(temp_path, "/");
    while (component != NULL) {
        struct direntv6 match;
        int status = directory_findname(fs, component, current_inode, &match);
        if (status < 0) {
            return -1; 
        }

        current_inode = match.d_inumber;
        component = strtok(NULL, "/");
    }

    return current_inode;
}
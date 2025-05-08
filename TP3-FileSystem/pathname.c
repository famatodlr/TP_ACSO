
#include "pathname.h"
#include "directory.h"
#include "inode.h"
#include "diskimg.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

/**
 * TODO
 */
int pathname_lookup(struct unixfilesystem *fs, const char *pathname) {
    // Path vacío o nulo
    if (pathname == NULL || strlen(pathname) == 0) {
        return -1;
    }

    // Copia local para tokenizar (strtok modifica el string)
    char path_copy[1024];
    strncpy(path_copy, pathname, sizeof(path_copy));
    path_copy[sizeof(path_copy) - 1] = '\0';

    // Comenzamos desde el inodo raíz
    int current_inumber = 1;

    // Tokenizamos el path ignorando '/'
    char *token = strtok(path_copy, "/");
    while (token != NULL) {
        struct direntv6 dir_entry;

        // Buscar el token actual en el directorio actual
        if (directory_findname(fs, token, current_inumber, &dir_entry) < 0) {
            return -1;  // No se encontró el componente
        }

        // Actualizar el número de inodo para el siguiente nivel
        current_inumber = dir_entry.d_inumber;

        // Siguiente componente del path
        token = strtok(NULL, "/");
    }

    return current_inumber;
}

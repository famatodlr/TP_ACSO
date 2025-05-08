#include "directory.h"
#include "inode.h"
#include "diskimg.h"
#include "file.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

/**
 * Busca una entrada de directorio por su nombre.
 * Parametros:
 *    fs El sistema de archivos.
 *    name El nombre del archivo a buscar.
 *    dirinumber El número de inodo del directorio donde buscar.
 *    dirEnt Una estructura donde se almacenará la entrada encontrada.
 * 
 * Return:
 * 0 si se encuentra el archivo, -1 si no se encuentra.
 */
int directory_findname(struct unixfilesystem *fs, const char *name,
    int dirinumber, struct direntv6 *dirEnt) {
  
    struct inode dirInode;
    if (inode_iget(fs, dirinumber, &dirInode) != 0) {
        fprintf(stderr, "Error: no se pudo obtener el inodo %d\n", dirinumber);
        return -1;
    }

    int size = inode_getsize(&dirInode);
    int numBlocks = size / 512;
    if (size % 512 != 0) {
        numBlocks++;
    }

    for (int blockNum = 0; blockNum < numBlocks; blockNum++) {
        char buf[512];
        if (file_getblock(fs, dirinumber, blockNum, buf) != 0) {
            fprintf(stderr, "Error: no se pudo leer el bloque %d del directorio %d\n", blockNum, dirinumber);
            return -1;
        }

        for (int i = 0; i < 512; i += sizeof(struct direntv6)) {
            struct direntv6 *entry = (struct direntv6 *)(buf + i);

            if (entry->d_inumber == 0) {
                continue;
            }

            // Comparación robusta: no permite strings más largos que 14
            if (strlen(name) <= DIRNAMELEN &&
                strncmp(entry->d_name, name, DIRNAMELEN) == 0) {
                *dirEnt = *entry;
                // printf("Encontrado '%s' en inodo %d\n", name, entry->d_inumber); // debug opcional
                return 0;
            }
        }
    }

    // printf("No se encontró '%s' en inodo %d\n", name, dirinumber); // debug opcional
    return -1;
}
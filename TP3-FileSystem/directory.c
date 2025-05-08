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
        return -1;  // Error al obtener el inodo del directorio
    }

    int numBlocks = inode_getsize(&dirInode) / 512;  // Calcular el número de bloques del directorio
    if (inode_getsize(&dirInode) % 512 != 0) {
        numBlocks++;  // Se agrega un bloque adicional
    }

    for (int blockNum = 0; blockNum < numBlocks; blockNum++) {
        char buf[512];  // Buffer para almacenar el bloque de datos
        if (file_getblock(fs, dirinumber, blockNum, buf) != 0) {
            return -1;  // Error al leer el bloque de datos del directorio
        }

        for (int i = 0; i < 512; i += sizeof(struct direntv6)) {
            struct direntv6 *entry = (struct direntv6 *)(buf + i);

            if (entry->d_inumber == 0) {
                continue;  // Entrada vacía, continuar con la siguiente
            }

            if (strncmp(entry->d_name, name, sizeof(entry->d_name)) == 0) {
                *dirEnt = *entry;
                return 0;  // Archivo encontrado
            }
        }
    }

    return -1;
}
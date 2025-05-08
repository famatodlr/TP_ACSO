#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include "file.h"
#include "inode.h"
#include "diskimg.h"

/**
 * Lee un bloque de datos del archivo identificado por inumber.
 */
int file_getblock(struct unixfilesystem *fs, int inumber, int blockNum, void *buf) {
    struct inode inp;
    if (inode_iget(fs, inumber, &inp) != 0) {
        return -1;  // Error al obtener el inodo
    }

    int blockAddr = inode_indexlookup(fs, &inp, blockNum);
    if (blockAddr < 0) {
        return -1;  // Error al buscar el bloque de datos
    }

    if (diskimg_readsector(fs->dfd, blockAddr, (char *)buf) != 0) {
        return -1;  // Error al leer el bloque de datos
    }

    return 0;
}
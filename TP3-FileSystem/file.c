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

    if (diskimg_readsector(fs->dfd, blockAddr, buf) != 0) {
        return -1;  // Error al leer el bloque de datos
    }

    int filesize = inode_getsize(&inp);
    if(filesize < 0){
        return -1;
    }

    int startByte = blockNum * DISKIMG_SECTOR_SIZE;
    if (startByte >= filesize){
        return 0;
    }

    int bytesLeft = filesize - startByte;
    return (bytesLeft >= DISKIMG_SECTOR_SIZE) ? DISKIMG_SECTOR_SIZE : bytesLeft;
}
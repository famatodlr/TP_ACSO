#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "file.h"
#include "inode.h"
#include "diskimg.h"

/**
 * Carga en 'buf' el contenido del bloque lógico 'blockNum' del archivo indicado por 'inumber'.
 * Devuelve la cantidad de bytes útiles leídos o -1 si ocurre un error.
 */
int file_getblock(struct unixfilesystem *fs, int inumber, int blockNum, void *buf) {
    struct inode inode_data;
    if (inode_iget(fs, inumber, &inode_data) < 0) {
        return -1;
    }

    int physical_block = inode_indexlookup(fs, &inode_data, blockNum);
    if (physical_block < 0) {
        return -1;
    }

    int bytes_read = diskimg_readsector(fs->dfd, physical_block, buf);
    if (bytes_read != DISKIMG_SECTOR_SIZE) {
        return -1;
    }

    int total_size = inode_getsize(&inode_data);
    int block_start = blockNum * DISKIMG_SECTOR_SIZE;

    if (total_size > block_start) {
        int valid_bytes = total_size - block_start;
        return (valid_bytes < DISKIMG_SECTOR_SIZE) ? valid_bytes : DISKIMG_SECTOR_SIZE;
    }

    return 0;
}
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "inode.h"
#include "diskimg.h"

/**
 * Devuelve en *inumber_pointer el inodo correspondiente a 'inumber', si existe.
 * Retorna 0 si tuvo éxito, o -1 ante errores (por ejemplo, si el número es inválido
 * o falla la lectura del disco).
 */
int inode_iget(struct unixfilesystem *fs, int inumber, struct inode *inumber_pointer) {
    if (inumber < 1) return -1;

    int inodes_per_sector = DISKIMG_SECTOR_SIZE / sizeof(struct inode);
    int sector = ((inumber - 1) / inodes_per_sector) + INODE_START_SECTOR;
    int index = (inumber - 1) % inodes_per_sector;

    struct inode buffer[inodes_per_sector];
    int bytes_read = diskimg_readsector(fs->dfd, sector, buffer);
    if (bytes_read != DISKIMG_SECTOR_SIZE) {
        return -1;
    }

    *inumber_pointer = buffer[index];
    return 0;
}

/**
 * A partir de un inodo y un número de bloque lógico, determina qué bloque físico
 * del disco lo almacena. Devuelve el número de bloque físico o -1 si hay algún error.
 */
int inode_indexlookup(struct unixfilesystem *fs, struct inode *inumber_pointer, int blockNum) {
    if (!(inumber_pointer->i_mode & IALLOC) || blockNum < 0) return -1;

    int addrs_per_block = DISKIMG_SECTOR_SIZE / sizeof(unsigned short);

    if (!(inumber_pointer->i_mode & ILARG)) {
        // Archivos chicos
        if (blockNum >= 8) return -1;
        int physical_block = inumber_pointer->i_addr[blockNum];
        return (physical_block != 0) ? physical_block : -1;
    }

    // Archivos grandes
    int simple_max = 7 * addrs_per_block;

    if (blockNum < simple_max) {
        int outer = blockNum / addrs_per_block;
        int inner = blockNum % addrs_per_block;

        if (outer >= 7) return -1;

        int indir_block = inumber_pointer->i_addr[outer];
        if (indir_block == 0) return -1;

        unsigned short indirect[addrs_per_block];
        int ok = diskimg_readsector(fs->dfd, indir_block, indirect);
        if (ok != DISKIMG_SECTOR_SIZE) return -1;

        int physical_block = indirect[inner];
        return (physical_block != 0) ? physical_block : -1;
    }

    int logical = blockNum - simple_max;
    int first_level_block = inumber_pointer->i_addr[7];
    if (first_level_block == 0) return -1;

    unsigned short first_level[addrs_per_block];
    int ok = diskimg_readsector(fs->dfd, first_level_block, first_level);
    if (ok != DISKIMG_SECTOR_SIZE) return -1;

    int first_idx = logical / addrs_per_block;
    int second_idx = logical % addrs_per_block;

    if (first_idx >= addrs_per_block) return -1;
    int second_level_block = first_level[first_idx];
    if (second_level_block == 0) return -1;

    unsigned short second_level[addrs_per_block];
    ok = diskimg_readsector(fs->dfd, second_level_block, second_level);
    if (ok != DISKIMG_SECTOR_SIZE) return -1;

    int physical_block = second_level[second_idx];
    return (physical_block != 0) ? physical_block : -1;
}

int inode_getsize(struct inode *inp) {
  return ((inp->i_size0 << 16) | inp->i_size1); 
}
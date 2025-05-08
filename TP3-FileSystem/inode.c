#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include "inode.h"
#include "diskimg.h"


/**
 * Carga un inodo desde el disco.
 */
int inode_iget(struct unixfilesystem *fs, int inumber, struct inode *inp) {
    if (inumber < 1) {
        return -1;   // inodo invalido
    }

    int inodes_per_block = DISKIMG_SECTOR_SIZE / sizeof(struct inode);
    int inode_block = INODE_START_SECTOR + (inumber - 1) / inodes_per_block;
    int offset = (inumber - 1) % (512 / sizeof(struct inode));

    struct inode buf[inodes_per_block];

    if (diskimg_readsector(fs->dfd, inode_block, buf) != DISKIMG_SECTOR_SIZE) {
        return -1;  // Error al leer el inodo
    }

    *inp = buf[offset];

    return 0;
}

/**
 * Busca un bloque de datos dentro de un inodo, teniendo en cuenta la posibilidad
 * de que sea un archivo grande con bloques indirectos o doblemente indirectos.
 */
int inode_indexlookup(struct unixfilesystem *fs, struct inode *inp, int blockNum) {
    if (!(inp->i_mode & IALLOC)){
        return -1;
    }

    if (blockNum < 0){
        return -1;
    }

    int ptrs_per_block = DISKIMG_SECTOR_SIZE / sizeof(unsigned short);

    if (!(inp->i_mode & ILARG)) {
        
        if (blockNum >= 8){
            return -1;
        }

        int block = inp->i_addr[blockNum];

        if (block == 0){
            return -1;
        }

        return block;
    } else {
        if ((inp->i_mode & ILARG) && inp->i_addr[0] != 0 && blockNum < 8) {
            // Caso especial: directorios marcados como grandes pero usan bloques directos
            return inp->i_addr[blockNum];
        }


        int simple_limit = 7 * ptrs_per_block;

        if (blockNum < simple_limit) {
            int indir_block_index = blockNum / ptrs_per_block;
            int indir_block_offset = blockNum % ptrs_per_block;

            if (indir_block_index >= 7){
                return -1;
            }
            int indir_block_num = inp->i_addr[indir_block_index];

            if (indir_block_num == 0){
                return -1;
            }

            unsigned short ptrs[ptrs_per_block];
            int res = diskimg_readsector(fs->dfd, indir_block_num, ptrs);

            if (res != DISKIMG_SECTOR_SIZE){
                return -1;
            }

            int data_block_num = ptrs[indir_block_offset];

            if (data_block_num == 0){
                return -1;
            }

            return data_block_num;

        } else {

            int double_blockNum = blockNum - simple_limit;
            int indir_block_num = inp->i_addr[7];
            if (indir_block_num == 0){
                return -1;
            }

            unsigned short first_level[ptrs_per_block];
            int res = diskimg_readsector(fs->dfd, indir_block_num, first_level);

            if (res != DISKIMG_SECTOR_SIZE){
                return -1;
            }

            int first_index = double_blockNum / ptrs_per_block;
            int second_index = double_blockNum % ptrs_per_block;

            if (first_index >= ptrs_per_block){
                return -1;
            }

            int second_indir_block = first_level[first_index];

            if (second_indir_block == 0){
                return -1;
            }

            unsigned short second_level[ptrs_per_block];
            res = diskimg_readsector(fs->dfd, second_indir_block, second_level);

            if (res != DISKIMG_SECTOR_SIZE){
                return -1;
            }

            int data_block_num = second_level[second_index];
            if (data_block_num == 0){
                return -1;
            }
            return data_block_num;
        }
    }
}

int inode_getsize(struct inode *inp) {
  return ((inp->i_size0 << 16) | inp->i_size1);
}

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
int inode_indexlookup(struct unixfilesystem *fs, struct inode *inp, int blockNum, int inumber) {
    if (!(inp->i_mode & IALLOC)) {
        printf("DEBUG: inode %d no está asignado (IALLOC no seteado)\n", inumber);
        return -1;
    }
    if (blockNum < 0) {
        printf("DEBUG: bloque %d inválido para inode %d\n", blockNum, inumber);
        return -1;
    }

    int ptrs_per_block = DISKIMG_SECTOR_SIZE / sizeof(unsigned short);

    // Archivos pequeños (no ILARG)
    if (!(inp->i_mode & ILARG)) {
        if (blockNum >= 8) {
            printf("DEBUG: bloque %d fuera de rango para acceso directo en inode %d\n", blockNum, inumber);
            return -1;
        }
        int block = inp->i_addr[blockNum];
        if (block == 0) {
            printf("DEBUG: entrada i_addr[%d] del inode %d es 0 (bloque no asignado)\n", blockNum, inumber);
            return -1;
        }
        printf("DEBUG: inode %d es pequeño, accediendo directamente a i_addr[%d] = %d\n", inumber, blockNum, block);
        return block;
    } else {
        // Archivos grandes (ILARG)
        int simple_limit = 7 * ptrs_per_block;

        if (blockNum < simple_limit) {
            // Indirección simple
            int indir_block_index = blockNum / ptrs_per_block;
            int indir_block_offset = blockNum % ptrs_per_block;

            
            if (indir_block_index >= 7) return -1;

            int indir_block_num = inp->i_addr[indir_block_index];
            if (indir_block_num == 0) {
                printf("DEBUG: bloque de indirección simple i_addr[%d] del inode %d es 0\n", indir_block_index, inumber);
                return -1;
            }

            unsigned short ptrs[ptrs_per_block];
            int res = diskimg_readsector(fs->dfd, indir_block_num, ptrs);
            if (res != DISKIMG_SECTOR_SIZE) {
                printf("DEBUG: error leyendo bloque de indirección simple %d para inode %d\n", indir_block_num, inumber);
                return -1;
            }

            int data_block_num = ptrs[indir_block_offset];
            if (data_block_num == 0) {
                printf("DEBUG: puntero en indirección simple ptrs[%d] = 0 en inode %d\n", indir_block_offset, inumber);
                return -1;
            }

            printf("DEBUG: inode %d usa indirección simple: bloque lógico %d mapea a físico %d\n", inumber, blockNum, data_block_num);
            return data_block_num;

        } else {
            // Indirección doble
            int double_blockNum = blockNum - simple_limit;
            int indir_block_num = inp->i_addr[7];
            if (indir_block_num == 0) {
                printf("DEBUG: bloque de indirección doble i_addr[7] del inode %d es 0\n", inumber);
                return -1;
            }

            unsigned short first_level[ptrs_per_block];
            int res = diskimg_readsector(fs->dfd, indir_block_num, first_level);
            if (res != DISKIMG_SECTOR_SIZE) {
                printf("DEBUG: error leyendo primer nivel de indirección doble %d para inode %d\n", indir_block_num, inumber);
                return -1;
            }

            int first_index = double_blockNum / ptrs_per_block;
            int second_index = double_blockNum % ptrs_per_block;

            if (first_index >= ptrs_per_block) {
                printf("DEBUG: primer índice %d fuera de rango en indirección doble para inode %d\n", first_index, inumber);
                return -1;
            }

            int second_indir_block = first_level[first_index];
            if (second_indir_block == 0) {
                printf("DEBUG: bloque de segundo nivel %d es 0 en indirección doble para inode %d\n", first_index, inumber);
                return -1;
            }

            unsigned short second_level[ptrs_per_block];
            res = diskimg_readsector(fs->dfd, second_indir_block, second_level);
            if (res != DISKIMG_SECTOR_SIZE) {
                printf("DEBUG: error leyendo segundo nivel de indirección doble %d para inode %d\n", second_indir_block, inumber);
                return -1;
            }

            int data_block_num = second_level[second_index];
            if (data_block_num == 0) {
                printf("DEBUG: puntero en segundo nivel ptrs[%d] = 0 en inode %d\n", second_index, inumber);
                return -1;
            }

            printf("DEBUG: inode %d usa indirección doble: bloque lógico %d mapea a físico %d\n", inumber, blockNum, data_block_num);
            return data_block_num;
        }
    }
}

int inode_getsize(struct inode *inp) {
  return ((inp->i_size0 << 16) | inp->i_size1);
}

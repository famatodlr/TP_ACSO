#include "directory.h"
#include "inode.h"
#include "diskimg.h"
#include "file.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

/**
 * Busca una entrada con el nombre dado dentro del directorio identificado por 'dirinumber'.
 * Si la encuentra, guarda el resultado en 'dirEnt' y devuelve 0. Retorna -1 si falla.
 */
int directory_findname(struct unixfilesystem *fs, const char *name,
                       int dirinumber, struct direntv6 *dirEnt) {
    struct inode inode_dir;
    if (inode_iget(fs, dirinumber, &inode_dir) < 0) {
        return -1;
    }

    if (!(inode_dir.i_mode & IALLOC) || (inode_dir.i_mode & IFMT) != IFDIR) {
        return -1;
    }

    int total_bytes = inode_getsize(&inode_dir);
    int total_entries = total_bytes / sizeof(struct direntv6);
    int entries_per_sector = DISKIMG_SECTOR_SIZE / sizeof(struct direntv6);

    char buffer[DISKIMG_SECTOR_SIZE];
    int current_index = 0;

    for (int blk = 0; ; blk++) {
        int read_bytes = file_getblock(fs, dirinumber, blk, buffer);
        if (read_bytes <= 0) break;

        int block_entries = read_bytes / sizeof(struct direntv6);
        struct direntv6 *dir_block = (struct direntv6 *)buffer;

        for (int j = 0; j < block_entries && current_index < total_entries; j++, current_index++) {
            if (dir_block[j].d_inumber == 0)
                continue;  // Salta entradas vacías

            if (strncmp(dir_block[j].d_name, name, sizeof(dir_block[j].d_name)) == 0) {
                *dirEnt = dir_block[j];
                return 0;
            }
        }
    }

    return -1;
}
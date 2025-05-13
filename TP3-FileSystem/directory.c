#include "directory.h"
#include "inode.h"
#include "diskimg.h"
#include "file.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

/**
 * TODO
 */
int directory_findname(struct unixfilesystem *fs, const char *name,
		int dirinumber, struct direntv6 *dirEnt) {
  struct inode dir_inode;
  if (inode_iget(fs, dirinumber, &dir_inode) < 0) {
    return -1;
  }

  if (!(dir_inode.i_mode & IALLOC) || ((dir_inode.i_mode & IFMT) != IFDIR)) {
    // No es un directorio válido
    return -1;
  }

  int dir_size = inode_getsize(&dir_inode);
  int num_entries = dir_size / sizeof(struct direntv6);
  int entries_per_block = DISKIMG_SECTOR_SIZE / sizeof(struct direntv6);

  char buf[DISKIMG_SECTOR_SIZE];

  int entry_index = 0;
  for (int block = 0; ; block++) {
    int bytes_read = file_getblock(fs, dirinumber, block, buf);
    if (bytes_read <= 0) break;

    int entries_in_block = bytes_read / sizeof(struct direntv6);
    struct direntv6 *entries = (struct direntv6 *)buf;

    for (int i = 0; i < entries_in_block && entry_index < num_entries; i++, entry_index++) {
      if (entries[i].d_inumber == 0)
        continue; // Entrada vacía

      // Comparar nombre (asegura terminación nula)
      if (strncmp(entries[i].d_name, name, sizeof(entries[i].d_name)) == 0) {
        *dirEnt = entries[i];
        return 0;
      }
    }
  }
  return -1;
}
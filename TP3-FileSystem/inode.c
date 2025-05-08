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

    int inode_block = INODE_START_SECTOR + (inumber - 1) / (512 / sizeof(struct inode));
    int offset = (inumber - 1) % (512 / sizeof(struct inode));


    if (diskimg_readsector(fs->dfd, inode_block, (char *)inp) != 0) {
        return -1;  // Error al leer el inodo
    }

    *inp = inp[offset];

    return 0;
}

/**
 * Busca un bloque de datos dentro de un inodo, teniendo en cuenta la posibilidad
 * de que sea un archivo grande con bloques indirectos o doblemente indirectos.
 */
int inode_indexlookup(struct unixfilesystem *fs, struct inode *inp, int blockNum) {
    // Verifica que el bloque sea válido
    if (blockNum < 0 || blockNum >= 8) {
        return -1;
    }

    if ((inp->i_mode & ILARG) == 0) {
        return inp->i_addr[blockNum]; 
    }

    if (blockNum < 7) {
        return inp->i_addr[7] + blockNum;
    } else {
        return -1;
    }
}

int inode_getsize(struct inode *inp) {
  return ((inp->i_size0 << 16) | inp->i_size1);
}

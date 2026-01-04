#include <defs.h>
#include <string.h>
#include <vfs.h>
#include <inode.h>
#include <error.h>
#include <assert.h>

/*
 * get_device- Common code to pull the device name, if any, off the front of a
 *             path and choose the inode to begin the name lookup relative to.
 */

static int
get_device(char *path, char **subpath, struct inode **node_store) {
    int i, slash = -1, colon = -1;//定义变量
    for (i = 0; path[i] != '\0'; i ++) {//遍历path字符串
        if (path[i] == ':') { colon = i; break; }//找到第一个冒号的位置
        if (path[i] == '/') { slash = i; break; }//找到第一个斜杠的位置
    }
    if (colon < 0 && slash != 0) {//如果没有冒号且斜杠不是第一个字符，说明是相对路径
        /* *
         * No colon before a slash, so no device name specified, and the slash isn't leading
         * or is also absent, so this is a relative path or just a bare filename. Start from
         * the current directory, and use the whole thing as the subpath.
         * */
        *subpath = path;//子路径就是整个path
        return vfs_get_curdir(node_store);//获取当前目录的inode
    }
    if (colon > 0) {//如果冒号在第一个位置之后，说明有设备名
        /* device:path - get root of device's filesystem */
        path[colon] = '\0';//将冒号替换为字符串结束符，分割设备名和路径

        /* device:/path - skip slash, treat as device:path */
        while (path[++ colon] == '/');//跳过冒号后的斜杠
        *subpath = path + colon;//子路径从冒号后的第一个非斜杠字符开始
        return vfs_get_root(path, node_store);//获取指定设备的根inode
    }

    /* *
     * we have either /path or :path
     * /path is a path relative to the root of the "boot filesystem"
     * :path is a path relative to the root of the current filesystem
     * */
    int ret;
    if (*path == '/') {//如果path以斜杠开头，说明是根路径
        if ((ret = vfs_get_bootfs(node_store)) != 0) {//获取引导文件系统的根inode
            return ret;
        }
    }
    else {
        assert(*path == ':');//否则path应该以冒号开头
        struct inode *node;//定义inode指针
        if ((ret = vfs_get_curdir(&node)) != 0) {
            return ret;
        }
        /* The current directory may not be a device, so it must have a fs. */
        assert(node->in_fs != NULL);
        *node_store = fsop_get_root(node->in_fs);
        vop_ref_dec(node);
    }

    /* ///... or :/... */
    while (*(++ path) == '/');//跳过冒号或斜杠后的所有斜杠
    *subpath = path;
    return 0;
}

/*
 * vfs_lookup - get the inode according to the path filename
 */
int
vfs_lookup(char *path, struct inode **node_store) {
    int ret;
    struct inode *node;
    if ((ret = get_device(path, &path, &node)) != 0) {
        return ret;
    }
    if (*path != '\0') {
        ret = vop_lookup(node, path, node_store);
        vop_ref_dec(node);
        return ret;
    }
    *node_store = node;
    return 0;
}

/*
 * vfs_lookup_parent - Name-to-vnode translation.
 *  (In BSD, both of these are subsumed by namei().)
 */
int
vfs_lookup_parent(char *path, struct inode **node_store, char **endp){
    int ret;
    struct inode *node;
    if ((ret = get_device(path, &path, &node)) != 0) {
        return ret;
    }
    *endp = path;
    *node_store = node;
    return 0;
}

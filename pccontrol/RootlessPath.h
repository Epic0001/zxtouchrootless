#ifndef ROOTLESS_PATH_H
#define ROOTLESS_PATH_H

#define ROOTLESS_PREFIX "/var/jb"
#define ROOTLESS_PATH(path) ROOTLESS_PREFIX path
#define ROOTLESS_PATH_NS(path) @ROOTLESS_PREFIX path

#endif

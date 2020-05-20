/* packer.c */

#include <stdio.h>
#include <string.h>

#define BITS_SIZE 2
#define BITS_OFF (6-BITS_SIZE)
#define MAX_SIZE (1<<BITS_SIZE)
#define MIN_OFF (-(1<<BITS_OFF))

static int count_similar(const unsigned char *p1, const unsigned char *p2,
                         const unsigned char *end) {
  int similar = 0;
  while (p2 < end && *p1 == *p2) {
    ++similar;
    p1 ++;
    p2 ++;
  }
  return similar;
}

#define flush_individual { \
  *w++ = individual_count-1; \
  memcpy(w, individual, individual_count); \
  w += individual_count; \
  individual += individual_count; \
  individual_count = 0; }

long pack(unsigned char *out, const unsigned char *in, long size) {
  unsigned char *w = out;
  const unsigned char *r = in;
  const unsigned char *end = in + size;
  const unsigned char *individual = in;
  int individual_count = 0;
  while (r < end) {
    const unsigned char *p = r-1;
    int best_size = 0;
    const unsigned char *best_pos = p;
    while (p > in && p >= (r-255)) {
      int size = count_similar(p, r, end);
      if (size > best_size) {
        best_size = size;
        best_pos = p;
      }
      p --;
    }
    if (best_size > 3) {
      /* copy */
      if (individual_count)
        flush_individual;
      if (best_size > 67)
        best_size = 67;
      individual += best_size;
      int offset = best_pos - r;
      r += best_size;
      best_size -= 4;

      if (best_size < MAX_SIZE && offset >= MIN_OFF)
        *w++ = 0x80 | (best_size&(MAX_SIZE-1))<<BITS_OFF
            | (offset&((1<<BITS_OFF)-1));
      else if (offset >= -256) {
        *w++ = 0xC0 | best_size;
        *w++ = offset;
      }
      else
        printf("problem: offset < -256 !!!\n");
      /* printf("size=%d offset=%d\n", best_size, offset); */
    } else {
      /* individual bytes */
      individual_count ++;
      if (individual_count == 128)
        flush_individual;
      r ++;
    }
  }
  if (individual_count)
    flush_individual;
  return w-out;
}

long unpack(unsigned char *out, const unsigned char *in, long size) {
  unsigned char *w = out;
  const unsigned char *r = in;
  const unsigned char *end = in + size;
  while (r < end) {
    /* printf("%4x %4x\n", w-out, r-in); */
    int size = (signed char)(*r++);
    if (size >= 0) {
      while (size-- >= 0)
        *w ++ = *r ++;
    } else {
      int offset;
      if ((size & 0xC0) == 0xC0) {
        offset = -256 | (signed char)(*r++);
        size &= 0x3F;
      } else {
        offset = size | (-1<<BITS_OFF);
        size = (size>>BITS_OFF) & (MAX_SIZE-1);
      }

      /* printf("size=%d offset=%d\n", size, offset); */
      size += 3;
      while (size-- >= 0) {
        *w = *(w+offset);
        w ++;
      }
    }
  }
  return w-out;
}

int main(int argc, char **argv) {
  FILE *fd = fopen(argv[1], "r");
  if (!fd) {
    perror(argv[1]);
    return 1;
  }

  fseek(fd, 0, SEEK_END);
  long in_size = ftell(fd);
  fseek(fd, 0, SEEK_SET);

  unsigned char in_file[in_size];
  unsigned char out_file[in_size*2];
  fread(in_file, 1, in_size, fd);
  fclose(fd);

  long packed_size = pack(out_file, in_file, in_size);

  printf("size=%ld packed=%ld\n", in_size, packed_size);

  unsigned char buffer[in_size*2];
  long unpacked_size = unpack(buffer, out_file, packed_size);
  if (memcmp(in_file, buffer, in_size)) {
    printf("Problem %ld %ld\n", in_size, unpacked_size);
    fd = fopen("out.upk", "w");
    fwrite(buffer, 1, unpacked_size, fd);
    fclose(fd);
  }
  else
    printf("Depack ok\n");

  fd = fopen("out.pck", "w");
  fwrite(out_file, 1, packed_size, fd);
  fclose(fd);

  return 0;
}
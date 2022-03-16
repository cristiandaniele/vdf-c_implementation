#ifndef LIB_VDF_H
#define LIB_VDF_H
#include "lib-mesg.h"
#include <assert.h>
#include <gmp.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include "lib-timing.h"
#include <libgen.h>
#include <nettle/md5.h>
#include <nettle/sha1.h>
#include <nettle/sha2.h>
#include <nettle/sha3.h>
#define rsa_mr_iterations 12

struct pp_struct {
    mpz_t N;
    unsigned long  T;
    int hash_f; //1,2,3
};
typedef struct pp_struct *pp_ptr;
typedef struct pp_struct pp_t[1];

struct output_eval_struct {
    mpz_t g; //H(x)
    mpz_t h; //output
    mpz_t proof;
};

typedef struct output_eval_struct *output_eval_ptr;
typedef struct output_eval_struct output_eval_t[1];

struct proof_metadata_struct {
    mpz_t l; //a prime number
    mpz_t q;
    mpz_t r_prover;
    mpz_t r_verifier;
    mpz_t _tmp;//2^t
};

typedef struct proof_metadata_struct *proof_metadata_ptr;
typedef struct proof_metadata_struct proof_metadata_t[1];

void setup(pp_t ,unsigned int ,gmp_randstate_t,int,unsigned long );
void printPublicParameters(pp_t);
void eval(int, pp_t ,output_eval_t );
void debug();
#endif


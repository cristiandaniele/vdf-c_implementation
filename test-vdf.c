#include "lib-vdf.h"
#include "lib-mesg.h"
#include "lib-timing.h"
#include <gmp.h>
#include <libgen.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <string.h>


#define prng_sec_level 128
#define default_mod_bits 4096

#define sampling_time 5 /* secondi */
#define max_samples (sampling_time * 200)

#define HASH_FUNCTION 2
//1000000
#define T 10
int main() {
    elapsed_time_t time;
    timestamp_t before,after;
    set_messaging_level(msg_very_verbose);
    pp_t pp;

    output_eval_t output_eval;
    proof_metadata_t proof_metadata;
    gmp_randstate_t prng;

    printf("Calibrazione strumenti per il timing...\n");
    calibrate_clock_cycles_ratio();
    detect_clock_cycles_overhead();
    detect_timestamp_overhead();

    printf("\nInizializzazione PRNG...\n");
    gmp_randinit_default(prng);
    gmp_randseed_os_rng(prng, prng_sec_level);

    setup(pp,default_mod_bits,prng,HASH_FUNCTION,T);

    printPublicParameters(pp);

    printf("Start eval/proof crafting..\n");
//    get_timestamp(before);
//    printf("%lu",before);
    eval(10,pp,output_eval);
    pmesg_mpz(msg_very_verbose, "g:", output_eval->g);
    pmesg_mpz(msg_very_verbose, "Y:", output_eval->h);
    getRandom_mpzl(proof_metadata); //il verifier manda al prover un l primo random
    find_q_r(pp,proof_metadata); //il prover computa q,r
    crafting_proof_W(pp,proof_metadata,output_eval);//il prover manda la proof g*q al verifier
//    get_timestamp(after);
//    printf("%d",get_elapsed_time_from_timestamp( before, after));
    printf("End eval/proof crafting..\n");

    printf("Start verify..\n");
    verify_proof_W(pp,proof_metadata,output_eval);//verifica
    printf("End verify..\n");
    

}

#include "parc-macros.h"
    TEST_PARC_BEGIN
    li $2, 0;  
    li $3, 30; 
    li $4, 40;
    bne $0, $2, 1f; 
    li $2, 20; 
    # try to mispseculate a branch here so Branch evalutaes to true. 
    bne $0, $2, 1f; 
    li $2, 0; 
1:  beq $0, $2, 2f; 
    TEST_PARC_END
2:  TEST_CHECK_FAIL;




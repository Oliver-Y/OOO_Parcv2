#include "parc-macros.h"
    TEST_PARC_BEGIN
    li $4, 40; 
    li $2, 20 
    li $3, 30 
    mul $7, $2, $3; 
    addiu $7, $4, 0; 
    TEST_CHECK_EQ($7, 40);
    TEST_INSERT_NOPS( 4 ); 
    TEST_PARC_END

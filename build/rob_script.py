for i in range(0,16): 
    print(  f"wire[7:0] rob_{i} =" + '{' + f"rob[{i}][VALID],rob[{i}][PENDING],rob[{i}][SPEC], rob[{i}][7:3]" + "};"); 

    
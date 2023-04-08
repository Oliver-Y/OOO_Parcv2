for i in range(0,16): 
    print(  f"wire[6:0] rob_{i} =" + '{' + f"rob[{i}][VALID],rob[{i}][PENDING], rob[{i}][6:2]" + "};"); 

    
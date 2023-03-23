
/*

 #####            #####                         
#     # #    # # #     # #    # # #      #####  
#       #    # # #       #    # # #      #    # 
 #####  #    # # #  #### #    # # #      #    # 
      # #    # # #     # #    # # #      #    # 
#     # #    # # #     # #    # # #      #    # 
 #####   ####  #  #####   ####  # ###### #####




   ___  _    _ _     _            ___       __ _                       
  / _ \| |__| (_)_ _(_)___ _ _   / __| ___ / _| |___ __ ____ _ _ _ ___ 
 | (_) | '_ \ | \ V / / _ \ ' \  \__ \/ _ \  _|  _\ V  V / _` | '_/ -_)
  \___/|_.__/_|_|\_/|_\___/_||_| |___/\___/_|  \__|\_/\_/\__,_|_| \___|
                                                                       
*/


// Forum module: represents the main functionalities of the forum in Suiguild 
module suiguild::Errors{
    

    friend suiguild::suiguild;
   // friend Suiguild::oracle;
    
    const ERROR_POST_OVERFLOW: u64 = 1;
    const ERROR_NEEDED_REF: u64 = 2;
    const ERROR_UNPREDICTED_ACTION: u64 = 3;
    const ERROR_WRONG_ACTION: u64 = 4; 

     //------Oracle Errors

    const EOwnerOnly: u64 = 0;
    const EValidatorOnly: u64 = 1;



    public fun GET_ERROR_POST_OVERFLOW() :u64 {
        return ERROR_POST_OVERFLOW
    }

    public fun GET_ERROR_NEEDED_REF() :u64 {
        return ERROR_NEEDED_REF
    }

    public fun GET_ERROR_UNPREDICTED_ACTION() :u64 {
        return ERROR_UNPREDICTED_ACTION
    }

    public fun GET_ERROR_WRONG_ACTION() :u64 {
        return ERROR_WRONG_ACTION
    }


    public fun GET_EOwnerOnly() :u64 {
        return EOwnerOnly
    }

    public fun GET_EValidatorOnly(): u64 {
        return EValidatorOnly
    }



}
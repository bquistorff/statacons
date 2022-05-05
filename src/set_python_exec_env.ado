* Copyright 2022. This work is licensed under a CC BY 4.0 license. 
* Even if you start Stata from a terminal with a specific Anaconda Python environment set
* you have to tell Stata to explicitly use this. Here's a simple command to do it.
* In the future maybe this could support other virtual environment types.
program set_python_exec_env
    local conda_prefix : env CONDA_PREFIX
    if "`conda_prefix'"!="" {
        set python_exec "`conda_prefix'/python.exe"
    }
end

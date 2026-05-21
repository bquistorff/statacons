cap program drop frames_tests_setup
program frames_tests_setup
    adopath ++ "../../src"
    cap mkdir outputs
    cap mkdir logs
end

cap program drop frames_tests_require_python
program frames_tests_require_python
    if "`c(python_exec)'" == "" {
        if `"$STATACONS_TEST_PYTHON"' != "" {
            set python_exec `"$STATACONS_TEST_PYTHON"'
        }
        else if `"$PYTHON_EXEC"' != "" {
            set python_exec `"$PYTHON_EXEC"'
        }
        else {
            cap which doenv
            if _rc == 0 {
                cap confirm file "../../.env"
                if _rc == 0 {
                    qui doenv using "../../.env"
                    if "`r(python_env)'" != "" {
                        set python_exec "`r(python_env)'"
                    }
                }
            }
        }
    }

    _assert "`c(python_exec)'" != "", ///
        msg("Need python_exec or STATACONS_TEST_PYTHON/PYTHON_EXEC or ../../.env")
end

cap program drop frames_tests_set_dev_src
program frames_tests_set_dev_src
    frames_tests_require_python
    local dev_src "`c(pwd)'/../../src"
    python: import os; os.environ["STATACONS_DEV_SRC"] = r"""`dev_src'"""; print("STATACONS_DEV_SRC =", os.environ["STATACONS_DEV_SRC"])
end

cap program drop store_modts
program store_modts
    syntax anything, local(string)

    frames_tests_require_python
    python: from pathlib import Path; from sfi import Macro; Macro.setLocal("`local'", str(Path(r"""`anything'""").stat().st_mtime_ns))
end

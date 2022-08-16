# A. Other Advanced Features

##  A.1. SConscripts and Hierarchical Builds

SConscripts allow dividing a project into parts. **Listing A1** shows how we can divide our
Introductory Example into separate `SConscript`s for dataprep and
analysis. Note the `Export()` and `Import()` statements needed to pass
environments and variables across the `SConstruct` and the
`SConscript`s.


**Listing A1: An SConstruct file with two SConscript files**
```
#--------- SConstruct file ----------
# **** Setup from pystatacons package *****
import pystatacons env = pystatacons.init_env()

# **** Substance begins  *****
Export('env') # allow SConscripts to import environment
SConscript('SConscript-dataprep')
SConscript('SConscript-analysis')


# -------- SConscript-dataprep ------------
# get environment from SConstruct
Import('env')
dataprep_Targets = ['outputs/auto-modified.dta']
Alias('dataprep',dataprep_Targets)
cmd_dataprep = env.StataBuild(
    target = dataprep_Targets,
    source ='code/dataprep.do' )
Depends(cmd_dataprep,['inputs/auto-original.dta'])
# allow SConscript-dataprep to access dataprep_Targets variable
Export('dataprep_Targets')


# -------- SConscript-analysis ------------
# get environment from SConstruct
Import('env')
# get dataprep_Targets variable exported by SConscript-dataprep
Import('dataprep_Targets')
analysis_Targets = ['outputs/scatterplot.pdf',
                    'outputs/regressionTable.tex']
Alias('analysis',analysis_Targets)
cmd_analysis = env.StataBuild(
     target = analysis_Targets,
     source = 'code/analysis.do' )
Depends(cmd_analysis, dataprep_Targets)
```

In addition to breaking up large `SConstruct`s into more manageable,
readable parts, using `SConscript`s allows assigning different options
or parameters to different parts of the project.

## A.2. Parallel Builds

SCons can manage *parallel builds*, conducting tasks that are not
interdependent simultaneously by dividing the computer's processors
among the tasks. This can reduce computation time relative to running
tasks sequentially.

At present, parallel builds are only supported in SCons itself, i.e.,
running `scons` from a terminal, not in `statacons`.

Using parallel builds without any modification to code can reduce
computation time. Furthermore, writing code with parallel builds in mind
can unlock additional gains. In our Applied Example, the event study
methodology of Sun and Abraham, J. Econometrics, 2021, is conducted for
four different variables. Each estimation is independent of the others,
so the four can be conducted in parallel. **Listing A2** provides the `SConscript` for this process. We
use an SConscript so that we can set the number of separate jobs for
these tasks without affecting the rest of the build. Note the
`SetOption('num_jobs',2)` line in the SConscript. We use 2 as a minimal
working example, users with more processors may wish to allow more jobs.

**Listing A2: SConstruct: Parallel Jobs in Applied Example**
```
# ** Setup
import pystatacons
env = pystatacons.init_env()
# use an sconsign database specific to this SConstruct
SConsignFile("sconsignParallel")
# set up parallel
# set default maximum of 2 jobs
SetOption('num_jobs',2)
# or set from command line, e.g.,
# scons -j 2 --file=SConstructParallel

# selection:
#  pare down dataset to variables and observations used
#  create one dataset per outcome variable
select_parallel = env.StataBuild(
  source = "code/sunabraham_select_parallel.do",
  target = ['outputs/dta/sunAbrahamSample_jallowrate.dta',
             'outputs/dta/sunAbrahamSample_awards.dta',
             'outputs/dta/sunAbrahamSample_decisions.dta',
             'outputs/dta/sunAbrahamSample_dispositions.dta'])
Depends(select_parallel, ['inputs/judgePanel.dta'])

# estimation
#   one task per outcome variable
cmds={}
for outcome in ["awards","decisions","jallowrate","dispositions"]:
cmds[outcome]=env.StataBuild(
  source = "code/sunabraham_estimation_"+outcome+\".do",
  target = ['outputs/dta/sunAbrahamResults_'+outcome+'.dta'],
  depends = ['outputs/dta/sunAbrahamSample_'+outcome+'.dta'] )

# plot results
figs_parallel = env.StataBuild(
 source = "code/sunabraham_graph_parallel.do",
 target = ['outputs/figures/sunabraham_parallel.png',
 'outputs/figures/lnallowrate_sunabraham_parallel.png'])
Depends(figs_parallel,
 ['outputs/dta/sunAbrahamResults_awards.dta',
 'outputs/dta/sunAbrahamResults_jallowrate.dta',
 'outputs/dta/sunAbrahamResults_decisions.dta',
 'outputs/dta/sunAbrahamResults_dispositions.dta'])
```

We have included the do-files for this parallel build in our
Supplemental Materials online. The basic idea is that (1) for each
outcome variable, we (a) create a dataset with that variable and the
relevant controls and identifiers, (b) perform the estimate for that
outcome and save the results in a dataset, then (2) once the estimation
is complete for all four variables, we combine the estimation results
for the four outcome variables and present the results.

The gains from parallel builds will depend on many factors, including
the nature of the task, the hardware, version of Stata, file size, and
the system I/O throughput. For example, User A with 8 processors but a
4-core version of Stata MP will likely experience greater *relative*
gains by adding a second, parallel job than User B with 8 processors and
8-core Stata MP: User A was only using 4 processors previously, and now
can use all 8 simultaneously, still applying 4 to each task; User B was
previously devoting 8 processors to each task sequentially, and now will
devote 4 processors to each task simultaneously.[^1]. Similarly, tasks
that use only a small fraction of the available RAM can run in parallel
without much cost to the speed of the individual tasks, while tasks that
are demanding of available RAM may not be sped up as much when run in
parallel. Finally, as noted in the paper, `parallel` (Vega Yon and
Quistorff, Stata Journal, 2019) is a better option for bootstrapping or
simulation.

Some care should be taken in writing code in these cases -- while there
is no issue with multiple Stata processes *accessing* the same dataset
at once, it is important that parallel tasks not *write* to the same
dataset. This just requires a bit of caution that no output filenames
are repeated across jobs.


[^1]: For some rough guidance on the types of tasks more or less likely
    to benefit from parallel builds, see the "Stata/MP Performance
    Report" (<https://www.stata.com/statamp/report.pdf>) for data on
    speed gains as the number of cores increases for different commands.
    Note that the gains as the number of cores increases is *negatively*
    related to gains from parallel builds if a fixed number of cores are
    being divided among tasks.


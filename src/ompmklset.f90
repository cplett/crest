!================================================================================!
! This file is part of crest.
!
! Copyright (C) 2018-2020 Philipp Pracht
!
! crest is free software: you can redistribute it and/or modify it under
! the terms of the GNU Lesser General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! crest is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU Lesser General Public License for more details.
!
! You should have received a copy of the GNU Lesser General Public License
! along with crest.  If not, see <https://www.gnu.org/licenses/>.
!================================================================================!

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!c OMP and MKL parallelization settings 
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!xTB uses OMP parallelization. This can be controlled by setting
!the MKL_NUM_THREADS and OMP_NUM_THREADS enviornment variables.

subroutine ompmklset(omp,maxrun,maximum)
      use iomod
      implicit none
      integer :: omp,maxrun,threads
      real*8 :: omp1,omp2
      character(len=256) :: atmp
      integer :: OMP_GET_NUM_THREADS,OMP_GET_NUM_PROCS
      integer :: OMP_GET_MAX_THREADS,dummy5 ,io
      logical :: maximum

      if(omp.gt.OMP_GET_NUM_PROCS())then
         omp=OMP_GET_NUM_PROCS()
      endif

      if(maximum)then
         dummy5=omp*MAXRUN
         !write(atmp,'(''OMP_NUM_THREADS='',i0)') dummy5
         !call PUTENV(trim(atmp)//char(0))
         !write(atmp,'(''MKL_NUM_THREADS='',i0)') dummy5
         !call PUTENV(trim(atmp)//char(0))
         io = setenv('OMP_NUM_THREADS',dummy5)
         io = setenv('MKL_NUM_THREADS',dummy5)
      else
         !write(atmp,'(''OMP_NUM_THREADS='',i0)') omp
         !call PUTENV(trim(atmp)//char(0))
         !write(atmp,'(''MKL_NUM_THREADS='',i0)') omp
         !call PUTENV(trim(atmp)//char(0))
         io = setenv('OMP_NUM_THREADS',omp)
         io = setenv('MKL_NUM_THREADS',omp)

      write(*,*)
      write(*,*) '==================================='
      write(*,'(''  # threads ='',9x,i3)')omp
      dummy5=omp * MAXRUN
      if(dummy5.gt.OMP_GET_NUM_PROCS())then
         write(*,*) '! Warning: unreasonable combination of         !'
         write(*,*) '! # of threads and # of parallel xTB calls.    !'
         write(*,*) '! Adjusted to:                                 !'
         omp1 = real(OMP_GET_NUM_PROCS())
         omp2 = real(omp)
         MAXRUN=floor((omp1/omp2))
      endif
      write(*,'(''  parallel xTB calls:''1x,i3)'),MAXRUN
      write(*,*) '==================================='
      write(*,*)
      endif
end subroutine ompmklset

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!c OMP and MKL parallelization settings (short routine)
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

subroutine ompquickset(omp,maxrun)
      use iomod
      implicit none
      integer,intent(in) :: omp,maxrun
      integer :: io

      io = setenv('OMP_NUM_THREADS',omp)
      io = setenv('MKL_NUM_THREADS',omp)

end subroutine ompquickset


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!c OMP and MKL parallelization settings, getting the settings with maximum number of OMP threads
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
subroutine ompset_max(omp,maxrun)
      use iomod
      implicit none
      integer,intent(inout) :: omp,maxrun
      integer :: io

      omp=omp*maxrun
      maxrun=1

      io = setenv('OMP_NUM_THREADS',omp)
      io = setenv('MKL_NUM_THREADS',omp)

end subroutine ompset_max



!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!c OMP and MKL parallelization settings, getting the settings with minimum number of OMP threads
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
subroutine ompset_min(omp,maxrun)
      use iomod
      implicit none
      integer,intent(inout) :: omp,maxrun
      integer :: io

      maxrun=omp*maxrun
      omp=1

      io = setenv('OMP_NUM_THREADS',omp)
      io = setenv('MKL_NUM_THREADS',omp)

end subroutine ompset_min




!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!c OMP and MKL autoset switchcase routine
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
subroutine ompautoset(threads,mode,omp,maxrun,factor)
      implicit none
      integer,intent(in) :: mode,factor
      integer,intent(inout) :: threads,omp,maxrun
      integer :: OMP_GET_NUM_PROCS
      real*8 :: dum1,dum2
      character(len=256) :: atmp

      if(threads.eq.0)then                    !special case
         threads=OMP_GET_NUM_PROCS()
      endif

      if(threads.gt.OMP_GET_NUM_PROCS())then  !limitation critirium 1: don't try to use more threads than available
         threads=OMP_GET_NUM_PROCS()
      endif

      if((maxrun.gt.threads).or.(omp.gt.threads))then   !limitation critirium 2: don't use stupid maxrun or omp settings
         maxrun=threads
         omp=1
      endif

      dum1=float(omp)*float(maxrun)
      if(dum1.lt.float(threads))then !limitation critirium 3: use the maximum number of threads
         maxrun=threads
         omp=1
      endif

      select case( mode )
        case( 1 )   !maximum number of OMP threads
          call ompset_max(omp,maxrun)
        case( 2 )   !maximum number of parallel jobs
          call ompset_min(omp,maxrun)
        case( 3 )   !run multiple jobs each on multiple threads
          dum1=float(threads)/float(factor)
          if(dum1.ge.2)then
             maxrun=factor
             omp=floor(dum1)
             call ompquickset(omp,maxrun)
          else
             call ompset_min(omp,maxrun)
          endif
        case( 4 ) !max number of threads for confscript internal routines (does not apply to the system calls)
          call OMP_Set_Num_Threads(threads)
          call MKL_Set_Num_Threads(threads)
        case( 5 ) !max number of threads for confscript to 1 (so that confscript itself doesn't block to many cores)
          call OMP_Set_Num_Threads(1)
          call MKL_Set_Num_Threads(1)
        case( 6 ) !case 2 combined with case 4, for OMP parallel task loop ---> each individual xTB job has only 1 thread, confscript has maximum number of threads to manage task list
          call ompset_min(omp,maxrun)
          call OMP_Set_Num_Threads(maxrun)
          call MKL_Set_Num_Threads(maxrun)
        case( 7 ) !case 3, but for OMP parallelization
          dum1=float(threads)/float(factor)
          if(dum1.ge.2)then
             maxrun=factor
             omp=floor(dum1)
             call ompquickset(omp,maxrun)
          else
             call ompset_min(omp,maxrun)
          endif
          call OMP_Set_Num_Threads(maxrun)
          call MKL_Set_Num_Threads(maxrun)
        case( 8 ) !--- set OMP threads to max. or a given maximum, i.e. use an upper limit for the threads
          omp=min(threads,factor)
          maxrun=1
          call ompquickset(omp,maxrun)
          call OMP_Set_Num_Threads(maxrun)
          call MKL_Set_Num_Threads(maxrun)
        case default  !done if omp and MAXRUN are valid and 
          call ompquickset(omp,maxrun)
      end select     


end subroutine ompautoset


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!c get omp/mkl automatically from the global variables
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
subroutine ompgetauto(threads,omp,maxrun)
      use iomod
      implicit none
      integer,intent(inout) :: threads,omp,maxrun
      integer :: OMP_GET_THREAD_NUM,OMP_GET_NUM_THREADS
      integer :: nproc,TID
      integer :: r,io 
      character(len=256) :: atmp,val

!!$OMP PARALLEL PRIVATE(TID)
!      TID = OMP_GET_THREAD_NUM()
!      IF (TID .EQ. 0) THEN
!         nproc = OMP_GET_NUM_THREADS()
         !write(*,*) '============================='
         !write(*,*) ' # threads =', nproc
         !write(*,*) '============================='
!      END IF
!!$OMP END PARALLEL 

      call getenv('OMP_NUM_THREADS',val)
      read(val,*,iostat=r) nproc
      if(r.ne.0)then
         nproc=1
      endif


      threads=nproc
      maxrun=1
      omp=nproc

end subroutine ompgetauto



!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!c print omp/mkl automatically from the global variables
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
subroutine ompprint()
      implicit none
      integer :: OMP_GET_THREAD_NUM,OMP_GET_NUM_THREADS
      integer :: nproc,TID
      integer :: r
      character(len=256) :: atmp,val

      call getenv('OMP_NUM_THREADS',val)
      read(val,*,iostat=r) nproc
      if(r.ne.0)then
         nproc=1
      endif
      write(*,*) '============================='
      write(*,*) ' # threads =', nproc
      write(*,*) '============================='
end subroutine ompprint


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!c print omp/mkl threads that are used at the moment
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
subroutine ompprint_intern()
      implicit none
      integer :: OMP_GET_THREAD_NUM,OMP_GET_NUM_THREADS
      integer :: nproc,TID
      integer :: r
      character(len=256) :: atmp,val

!$OMP PARALLEL PRIVATE(TID)
      TID = OMP_GET_THREAD_NUM()
      IF (TID .EQ. 0) THEN
         nproc = OMP_GET_NUM_THREADS()
         write(*,*) '============================='
         write(*,*) ' # threads =', nproc
         write(*,*) '============================='
      END IF
!$OMP END PARALLEL 
end subroutine ompprint_intern



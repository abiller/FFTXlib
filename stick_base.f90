!
! Copyright (C) Quantum ESPRESSO group
!
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!=----------------------------------------------------------------------=
   MODULE stick_base
!=----------------------------------------------------------------------=

        IMPLICIT NONE
        PRIVATE
        SAVE

        PUBLIC :: sticks_maps, sticks_sort, sticks_countg, sticks_dist, sticks_pairup
        PUBLIC :: sticks_owner, sticks_deallocate, sticks_maps_scalar, sticks_ordered_dist

! ...   sticks_owner :   stick owner, sticks_owner( i, j ) is the index of the processor
! ...     (starting from 1) owning the stick whose x and y coordinate  are i and j.

        INTEGER, ALLOCATABLE, TARGET :: sticks_owner( : , : )

        INTEGER, PARAMETER :: DP = selected_real_kind(14,200)

!=----------------------------------------------------------------------=
   CONTAINS
!=----------------------------------------------------------------------=

      SUBROUTINE sticks_maps( tk, ub, lb, b1, b2, b3, gcut, gcutw, gcuts, st, stw, sts, me, nproc, comm )

#if defined(__MPI)
          INCLUDE 'mpif.h'
#endif

          LOGICAL, INTENT(in) :: tk    !  if true use the full space grid
          INTEGER, INTENT(in) :: ub(:) !  upper bounds for i-th grid dimension
          INTEGER, INTENT(in) :: lb(:) !  lower bounds for i-th grid dimension
          REAL(DP) , INTENT(in) :: b1(:), b2(:), b3(:) ! reciprocal space base vectors
          REAL(DP) , INTENT(in) :: gcut   ! cut-off for potentials
          REAL(DP) , INTENT(in) :: gcutw  ! cut-off for plane waves
          REAL(DP) , INTENT(in) :: gcuts  ! cut-off for smooth mesh
          INTEGER, INTENT(out) :: st( lb(1): ub(1), lb(2):ub(2) ) ! stick map for potential
          INTEGER, INTENT(out) :: stw(lb(1): ub(1), lb(2):ub(2) ) ! stick map for wave functions
          INTEGER, INTENT(out) :: sts(lb(1): ub(1), lb(2):ub(2) ) ! stick map for smooth mesh
          INTEGER, INTENT(in) :: me ! my proc id (starting from 0)
          INTEGER, INTENT(in) :: nproc ! number of proc in the g-vec group
          INTEGER, INTENT(in) :: comm ! communicator of the g-vec group

          INTEGER :: i, j, k, kip, ierr
          REAL(DP) :: gsq

          stw  = 0
          st   = 0
          sts  = 0

! ...       Here find the basic maps of sticks st, stw and sts for the potential
! ...       cut-off gcut, wavefunction cut-off gcutw, and smooth mesh cut-off gcuts

! ...       st(i,j) will contain the number of G vectors of the stick whose
! ...       indices are (i,j).

#if defined (__EKO)
          WRITE(*,*) ! Workaround for EKOPath compiler bug
#endif
          IF( .not. tk ) THEN

            kip = 0 + abs(lb(3)) + 1
            IF( mod( kip, nproc ) == me ) THEN
              st (0,0) = st (0,0) + 1
              stw(0,0) = stw(0,0) + 1
              sts(0,0) = sts(0,0) + 1
            ENDIF

            DO i= 0, 0
              DO j= 0, 0
                DO k= 1, ub(3)
                  kip = k + abs(lb(3)) + 1
                  IF( mod( kip, nproc ) == me ) THEN
                    gsq=    (dble(i)*b1(1)+dble(j)*b2(1)+dble(k)*b3(1) )**2
                    gsq=gsq+(dble(i)*b1(2)+dble(j)*b2(2)+dble(k)*b3(2) )**2
                    gsq=gsq+(dble(i)*b1(3)+dble(j)*b2(3)+dble(k)*b3(3) )**2
                    IF(gsq<=gcut ) THEN
                      st(i,j) = st(i,j) + 1
                      IF(gsq<=gcutw) THEN
                        stw(i,j) = stw(i,j) + 1
                      ENDIF
                      IF(gsq<=gcuts) THEN
                        sts(i,j) = sts(i,j) + 1
                      ENDIF
                    ENDIF
                  ENDIF
                ENDDO
              ENDDO
            ENDDO

            DO i = 0, 0
              DO j = 1, ub(2)
                DO k = lb(3), ub(3)
                  kip = k + abs(lb(3)) + 1
                  IF( mod( kip, nproc) == me ) THEN
                    gsq=    (dble(i)*b1(1)+dble(j)*b2(1)+dble(k)*b3(1) )**2
                    gsq=gsq+(dble(i)*b1(2)+dble(j)*b2(2)+dble(k)*b3(2) )**2
                    gsq=gsq+(dble(i)*b1(3)+dble(j)*b2(3)+dble(k)*b3(3) )**2
                    IF(gsq<=gcut ) THEN
                      st(i,j) = st(i,j) + 1
                      IF(gsq<=gcutw) THEN
                        stw(i,j) = stw(i,j) + 1
                      ENDIF
                      IF(gsq<=gcuts) THEN
                        sts(i,j) = sts(i,j) + 1
                      ENDIF
                    ENDIF
                  ENDIF
                ENDDO
              ENDDO
            ENDDO

            DO i = 1, ub(1)
              DO j = lb(2), ub(2)
                DO k = lb(3), ub(3)
                  kip = k + abs(lb(3)) + 1
                  IF( mod( kip, nproc) == me ) THEN
                    gsq=    (dble(i)*b1(1)+dble(j)*b2(1)+dble(k)*b3(1) )**2
                    gsq=gsq+(dble(i)*b1(2)+dble(j)*b2(2)+dble(k)*b3(2) )**2
                    gsq=gsq+(dble(i)*b1(3)+dble(j)*b2(3)+dble(k)*b3(3) )**2
                    IF(gsq<=gcut ) THEN
                      st(i,j) = st(i,j) + 1
                      IF(gsq<=gcutw) THEN
                        stw(i,j) = stw(i,j) + 1
                      ENDIF
                      IF(gsq<=gcuts) THEN
                        sts(i,j) = sts(i,j) + 1
                      ENDIF
                    ENDIF
                  ENDIF
                ENDDO
              ENDDO
            ENDDO

          ELSE

            DO i= lb(1), ub(1)
              DO j= lb(2), ub(2)
                DO k= lb(3), ub(3)
                  kip = k + abs(lb(3)) + 1
                  IF( mod( kip, nproc ) == me ) THEN
                    gsq=    (dble(i)*b1(1)+dble(j)*b2(1)+dble(k)*b3(1) )**2
                    gsq=gsq+(dble(i)*b1(2)+dble(j)*b2(2)+dble(k)*b3(2) )**2
                    gsq=gsq+(dble(i)*b1(3)+dble(j)*b2(3)+dble(k)*b3(3) )**2
                    IF(gsq<=gcut ) THEN
                      st(i,j) = st(i,j) + 1
                    ENDIF
                    IF(gsq<=gcutw) THEN
                      stw(i,j) = stw(i,j) + 1
                    ENDIF
                    IF(gsq<=gcuts) THEN
                      sts(i,j) = sts(i,j) + 1
                    ENDIF
                  ENDIF
                ENDDO
              ENDDO
            ENDDO

          ENDIF

#if defined(__MPI)
          CALL MPI_ALLREDUCE(MPI_IN_PLACE, st, size(st), MPI_INTEGER, MPI_SUM, comm, ierr)
          CALL MPI_ALLREDUCE(MPI_IN_PLACE, stw, size(stw), MPI_INTEGER, MPI_SUM, comm, ierr)
          CALL MPI_ALLREDUCE(MPI_IN_PLACE, sts, size(sts), MPI_INTEGER, MPI_SUM, comm, ierr)
#endif

        RETURN
      END SUBROUTINE sticks_maps

!=----------------------------------------------------------------------=

  SUBROUTINE sticks_maps_scalar( lgamma, ub, lb, b1, b2, b3, gcutm, gkcut, gcutms, stw, ngm, ngms )

    LOGICAL, INTENT(in) :: lgamma !  if true use gamma point simmetry
    INTEGER, INTENT(in) :: ub(:)  !  upper bounds for i-th grid dimension
    INTEGER, INTENT(in) :: lb(:)  !  lower bounds for i-th grid dimension
    REAL(DP) , INTENT(in) :: b1(:), b2(:), b3(:) ! reciprocal space base vectors
    REAL(DP) , INTENT(in) :: gcutm  ! cut-off for potentials
    REAL(DP) , INTENT(in) :: gkcut  ! cut-off for plane waves
    REAL(DP) , INTENT(in) :: gcutms  ! cut-off for smooth mesh
    !
    INTEGER, INTENT(out) :: ngm, ngms
    !
    !     stick map for wave functions, note that map is taken in YZ plane
    !
    INTEGER, INTENT(out) :: stw( lb(2) : ub(2), lb(3) : ub(3) )

    INTEGER :: i1, i2, i3, n1, n2, n3
    REAL(DP) :: amod

    ngm = 0
    ngms = 0
    stw = 0

    n1 = max( abs( lb(1) ), abs( ub(1) ) )
    n2 = max( abs( lb(2) ), abs( ub(2) ) )
    n3 = max( abs( lb(3) ), abs( ub(3) ) )

    loop1: DO i1 = - n1, n1
       !
       ! Gamma-only: exclude space with x<0
       !
       IF (lgamma .and. i1 < 0) CYCLE loop1
       !
       loop2: DO i2 = - n2, n2
          !
          ! Gamma-only: exclude plane with x=0, y<0
          !
          IF(lgamma .and. i1 == 0.and. i2 < 0) CYCLE loop2
          !
          loop3: DO i3 = - n3, n3
             !
             ! Gamma-only: exclude line with x=0, y=0, z<0
             !
             IF(lgamma .and. i1 == 0 .and. i2 == 0 .and. i3 < 0) CYCLE loop3
             !
             amod = (i1 * b1 (1) + i2 * b2 (1) + i3 * b3 (1) ) **2 + &
                    (i1 * b1 (2) + i2 * b2 (2) + i3 * b3 (2) ) **2 + &
                    (i1 * b1 (3) + i2 * b2 (3) + i3 * b3 (3) ) **2
             IF (amod <= gcutm)  ngm  = ngm  + 1
             IF (amod <= gcutms) ngms = ngms + 1
             IF (amod <= gkcut ) THEN
                stw( i2, i3 ) = 1
                IF (lgamma) stw( -i2, -i3 ) = 1
             ENDIF
          ENDDO loop3
       ENDDO loop2
    ENDDO loop1

    RETURN
  END SUBROUTINE sticks_maps_scalar


!=----------------------------------------------------------------------=

      SUBROUTINE sticks_sort( ngc, ngcw, ngcs, nct, idx, nproc )

! ...     This subroutine sorts the sticks indexes, according to
! ...     the length and type of the sticks, wave functions sticks
! ...     first, then smooth mesh sticks, and finally potential
! ...     sticks

        ! lengths of sticks, ngc for potential mesh, ngcw for wave functions mesh
        ! and ngcs for smooth mesh

        INTEGER, INTENT(in) :: ngc(:), ngcw(:), ngcs(:)
        INTEGER, INTENT(in) :: nproc ! number of proc in the g-vec group

        ! nct, total number of sticks

        INTEGER, INTENT(in) :: nct

        ! index, on output, new sticks indexes

        INTEGER, INTENT(out) :: idx(:)

        INTEGER  :: mc, nr3x, ic
        REAL(DP) :: dn3
        REAL(DP), ALLOCATABLE :: aux(:)

        nr3x = maxval( ngc(1:nct) ) + 1
        dn3  = REAL( nr3x )

        IF( nproc > 1 ) THEN
          ALLOCATE( aux( nct ) )
          DO mc = 1, nct
            aux(mc) = ngcw(mc)
            aux(mc) = dn3 * aux(mc) + ngcs(mc)
            aux(mc) = dn3 * aux(mc) + ngc(mc)
            aux(mc) = -aux(mc)
            idx(mc) = 0
          ENDDO
          CALL hpsort( nct, aux, idx)
          DEALLOCATE( aux )
        ELSE
          ic = 0
          DO mc = 1, nct
            IF( ngcw(mc) > 0 ) THEN
              ic = ic + 1
              idx(ic) = mc
            ENDIF
          ENDDO
          DO mc = 1, nct
            IF( ngcs(mc) > 0 .and. ngcw(mc) == 0 ) THEN
              ic = ic + 1
              idx(ic) = mc
            ENDIF
          ENDDO
          DO mc = 1, nct
            IF( ngc(mc) > 0 .and. ngcs(mc) == 0 .and. ngcw(mc) == 0 ) THEN
              ic = ic + 1
              idx(ic) = mc
            ENDIF
          ENDDO
        ENDIF

!!! TO REMOVE BEFORE COMMIT INTO SVN !!!
#if defined(__STICKS_DEBUG)
        WRITE( 6,*) '-----------------'
        WRITE( 6,*) 'STICKS_SORT DEBUG'
        DO mc = 1, nct
          WRITE( 6, fmt="(4I10)" ) idx(mc), ngcw( idx(mc) ), ngcs( idx(mc) ), ngc( idx(mc) )
        ENDDO
        WRITE( 6,*) '-----------------'
#endif
!!! TO REMOVE BEFORE COMMIT INTO SVN !!!

        RETURN
      END SUBROUTINE sticks_sort

!=----------------------------------------------------------------------=

    SUBROUTINE sticks_countg( tk, ub, lb, st, stw, sts, in1, in2, ngc, ngcw, ngcs )

      INTEGER, INTENT(in) :: ub(:), lb(:)
      INTEGER, INTENT(in) :: st( lb(1): ub(1), lb(2):ub(2) ) ! stick map for potential
      INTEGER, INTENT(in) :: stw(lb(1): ub(1), lb(2):ub(2) ) ! stick map for wave functions
      INTEGER, INTENT(in) :: sts(lb(1): ub(1), lb(2):ub(2) ) ! stick map for smooth mesh
      LOGICAL, INTENT(in) :: tk

      INTEGER, INTENT(out) :: in1(:), in2(:)
      INTEGER, INTENT(out) :: ngc(:), ngcw(:), ngcs(:)

      INTEGER :: j1, j2, i1, i2, nct, min_size

!
! ...     initialize the sticks indexes array ist
! ...     nct counts columns containing G-vectors for the dense grid
! ...     ncts counts columns contaning G-vectors for the smooth grid
!
      nct   = 0

      ngc   = 0
      ngcs  = 0
      ngcw  = 0

      min_size = min( size( in1 ), size( in2 ), size( ngc ), size( ngcw ), size( ngcs ) )

      DO j2 = 0, ( ub(2) - lb(2) )
        DO j1 = 0, ( ub(1) - lb(1) )

          i1 = j1
          IF( i1 > ub(1) ) i1 = lb(1) + ( i1 - ub(1) ) - 1

          i2 = j2
          IF( i2 > ub(2) ) i2 = lb(2) + ( i2 - ub(2) ) - 1

          IF( st( i1, i2 ) > 0 ) THEN

            ! this sticks contains G-vectors

            nct = nct + 1
            IF( nct > min_size ) &
              CALL fftx_error__(' sticks_countg ',' too many sticks ', nct )

            in1(nct) = i1
            in2(nct) = i2

            ngc(nct) = st( i1 , i2)
            IF( stw( i1, i2 ) > 0 ) ngcw(nct) = stw( i1 , i2)
            IF( sts( i1, i2 ) > 0 ) ngcs(nct) = sts( i1 , i2)

          ENDIF

          ! WRITE(7,fmt="(5I5)") i1, i2, nct, ngc(nct), ngcw( nct )

        ENDDO
      ENDDO

      RETURN
    END SUBROUTINE sticks_countg

!=----------------------------------------------------------------------=

    SUBROUTINE sticks_dist( tk, ub, lb, idx, in1, in2, ngc, ngcw, ngcs, nct, &
                            ncp, ncpw, ncps, ngp, ngpw, ngps, stown, stownw, stowns, nproc )

      LOGICAL, INTENT(in) :: tk

      INTEGER, INTENT(in) :: ub(:), lb(:), idx(:)
      INTEGER, INTENT(out) :: stown( lb(1): ub(1), lb(2):ub(2) ) ! stick map for potential
      INTEGER, INTENT(out) :: stownw(lb(1): ub(1), lb(2):ub(2) ) ! stick map for wave functions
      INTEGER, INTENT(out) :: stowns(lb(1): ub(1), lb(2):ub(2) ) ! stick map for smooth mesh

      INTEGER, INTENT(in) :: in1(:), in2(:)
      INTEGER, INTENT(in) :: ngc(:), ngcw(:), ngcs(:)
      INTEGER, INTENT(in) :: nct
      INTEGER, INTENT(out) :: ncp(:), ncpw(:), ncps(:)
      INTEGER, INTENT(out) :: ngp(:), ngpw(:), ngps(:)
      INTEGER, INTENT(in) :: nproc ! number of proc in the g-vec group

      INTEGER :: mc, i1, i2, i, j, jj, icnt

      ncp  = 0
      ncps = 0
      ncpw = 0
      ngp  = 0
      ngps = 0
      ngpw = 0

      stown  = 0
      stownw = 0
      stowns = 0

      icnt = 0

      DO mc = 1, nct

         i = idx( mc )
         i = idx( mc )
!
! index contains the desired ordering of sticks (see above)
!
         i1 = in1( i )
         i2 = in2( i )
!
         IF ( ( .not. tk ) .and. ( (i1 < 0) .or. ( (i1 == 0) .and. (i2 < 0) ) ) ) GOTO 30
!
         jj = 1

         IF ( ngcw(i) > 0 ) THEN
!
! this is an active sticks: find which processor has currently
! the smallest number of plane waves
!
            !jj = MOD( icnt, nproc ) + 1
            !icnt = icnt + 1

            DO j = 1, nproc
               IF ( ngpw(j) < ngpw(jj) ) THEN
                 jj = j
               ELSEIF ( ( ngpw(j) == ngpw(jj) ) .and. ( ncpw(j) < ncpw(jj) ) ) THEN
                 jj = j
               ENDIF
            ENDDO

         ELSE
!
! this is an inactive sticks: find which processor has currently
! the smallest number of G-vectors
!
            DO j = 1, nproc
               IF ( ngp(j) < ngp(jj) ) jj = j
            ENDDO

         ENDIF
!
         ! potential mesh

         ncp(jj) = ncp(jj) + 1
         ngp(jj) = ngp(jj) + ngc(i)
         stown(i1,i2) = jj

         ! smooth mesh

         IF ( ngcs(i) > 0 ) THEN
            ncps(jj) = ncps(jj) + 1
            ngps(jj) = ngps(jj) + ngcs(i)
            stowns(i1,i2) = jj
         ENDIF

         ! wave functions mesh

         IF ( ngcw(i) > 0 ) THEN
            ncpw(jj) = ncpw(jj) + 1
            ngpw(jj) = ngpw(jj) + ngcw(i)
            stownw(i1,i2) = jj
         ENDIF

 30      CONTINUE

      ENDDO

      RETURN
    END SUBROUTINE sticks_dist

!=----------------------------------------------------------------------=

    SUBROUTINE sticks_pairup( tk, ub, lb, idx, in1, in2, ngc, ngcw, ngcs, nct, &
                             ncp, ncpw, ncps, ngp, ngpw, ngps, stown, stownw, stowns, nproc )

      LOGICAL, INTENT(in) :: tk

      INTEGER, INTENT(in) :: ub(:), lb(:), idx(:)
      INTEGER, INTENT(inout) :: stown( lb(1): ub(1), lb(2):ub(2) ) ! stick map for potential
      INTEGER, INTENT(inout) :: stownw(lb(1): ub(1), lb(2):ub(2) ) ! stick map for wave functions
      INTEGER, INTENT(inout) :: stowns(lb(1): ub(1), lb(2):ub(2) ) ! stick map for wave functions

      INTEGER, INTENT(in) :: in1(:), in2(:)
      INTEGER, INTENT(in) :: ngc(:), ngcw(:), ngcs(:)
      INTEGER, INTENT(in) :: nct
      INTEGER, INTENT(out) :: ncp(:), ncpw(:), ncps(:)
      INTEGER, INTENT(out) :: ngp(:), ngpw(:), ngps(:)
      INTEGER, INTENT(in) :: nproc ! number of proc in the g-vec group

      INTEGER :: mc, i1, i2, i, jj

      IF ( .not. tk ) THEN

        !  when gamma symmetry is used only the sticks of half reciprocal space
        !  are generated, then here we pair-up the sticks with those of the other
        !  half of the space, using the gamma symmetry relation
        !  Note that the total numero of stick "nct" is not modified

        DO mc = 1, nct
           i = idx(mc)
           i1 = in1(i)
           i2 = in2(i)
           IF( i1 == 0 .and. i2 == 0 ) THEN
             jj = stown( i1, i2 )
             IF( jj > 0 ) ngp( jj ) = ngp( jj ) + ngc( i ) - 1
             jj = stowns( i1, i2 )
             IF( jj > 0 ) ngps( jj ) = ngps( jj ) + ngcs( i ) - 1
             jj = stownw( i1, i2 )
             IF( jj > 0 ) ngpw( jj ) = ngpw( jj ) + ngcw( i ) - 1
           ELSE
             jj = stown( i1, i2 )
             IF( jj > 0 ) THEN
               stown( -i1, -i2 ) = jj
               ncp( jj ) = ncp( jj ) + 1
               ngp( jj ) = ngp( jj ) + ngc( i )
             ENDIF
             jj = stowns( i1, i2 )
             IF( jj > 0 ) THEN
               stowns( -i1, -i2 ) = jj
               ncps( jj ) = ncps( jj ) + 1
               ngps( jj ) = ngps( jj ) + ngcs( i )
             ENDIF
             jj = stownw( i1, i2 )
             IF( jj > 0 ) THEN
               stownw( -i1, -i2 ) = jj
               ncpw( jj ) = ncpw( jj ) + 1
               ngpw( jj ) = ngpw( jj ) + ngcw( i )
             ENDIF
           ENDIF
        ENDDO

      ENDIF

      IF( allocated( sticks_owner ) ) DEALLOCATE( sticks_owner )
      ALLOCATE( sticks_owner( lb(1): ub(1), lb(2):ub(2) ) )

      sticks_owner( :, : ) = abs( stown( :, :) )

      RETURN
    END SUBROUTINE sticks_pairup

!=----------------------------------------------------------------------=

    SUBROUTINE sticks_ordered_dist( tk, ub, lb, idx, in1, in2, ngc, ngcw, ngcs, nct, &
                            ncp, ncpw, ncps, ngp, ngpw, ngps, stown, stownw, stowns, nproc )
!
! This routine works as sticks_dist only it distributes the sticks according to sticks_owner.
! This ensures that the gvectors for any 'smooth like grid' remain on the same proc as the
! original grid.
!
      LOGICAL, INTENT(in) :: tk

      INTEGER, INTENT(in) :: ub(:), lb(:), idx(:)
      INTEGER, INTENT(out) :: stown( lb(1): ub(1), lb(2):ub(2) ) ! stick map for potential
      INTEGER, INTENT(out) :: stownw(lb(1): ub(1), lb(2):ub(2) ) ! stick map for wave functions
      INTEGER, INTENT(out) :: stowns(lb(1): ub(1), lb(2):ub(2) ) ! stick map for smooth mesh

      INTEGER, INTENT(in) :: in1(:), in2(:)
      INTEGER, INTENT(in) :: ngc(:), ngcw(:), ngcs(:)
      INTEGER, INTENT(in) :: nct
      INTEGER, INTENT(out) :: ncp(:), ncpw(:), ncps(:)
      INTEGER, INTENT(out) :: ngp(:), ngpw(:), ngps(:)
      INTEGER, INTENT(in) :: nproc ! number of proc in the g-vec group

      INTEGER :: mc, i1, i2, i, j, jj

      ncp  = 0
      ncps = 0
      ncpw = 0
      ngp  = 0
      ngps = 0
      ngpw = 0

      stown  = sticks_owner
      stownw = 0
      stowns = 0

      DO mc = 1, nct

         i = idx( mc )
!
! index has no effect in this case
!
         i1 = in1( i )
         i2 = in2( i )
!
         IF ( ( .not. tk ) .and. ( (i1 < 0) .or. ( (i1 == 0) .and. (i2 < 0) ) ) ) GOTO 30
!
         ! potential mesh set according to sticks_owner

         jj = stown(i1,i2)
         ncp(jj) = ncp(jj) + 1
         ngp(jj) = ngp(jj) + ngc(i)

         ! smooth mesh

         IF ( ngcs(i) > 0 ) THEN
            ncps(jj) = ncps(jj) + 1
            ngps(jj) = ngps(jj) + ngcs(i)
            stowns(i1,i2) = jj
         ENDIF

         ! wave functions mesh

         IF ( ngcw(i) > 0 ) THEN
            ncpw(jj) = ncpw(jj) + 1
            ngpw(jj) = ngpw(jj) + ngcw(i)
            stownw(i1,i2) = jj
         ENDIF

 30      CONTINUE

      ENDDO

      RETURN
    END SUBROUTINE sticks_ordered_dist

!=----------------------------------------------------------------------=
    
!---------------------------------------------------------------------
    SUBROUTINE hpsort (n, ra, ind)
      !---------------------------------------------------------------------
      ! sort an array ra(1:n) into ascending order using heapsort algorithm.
      ! n is input, ra is replaced on output by its sorted rearrangement.
      ! create an index table (ind) by making an exchange in the index array
      ! whenever an exchange is made on the sorted data array (ra).
      ! in case of equal values in the data array (ra) the values in the
      ! index array (ind) are used to order the entries.
      ! if on input ind(1)  = 0 then indices are initialized in the routine,
      ! if on input ind(1) != 0 then indices are assumed to have been
      !                initialized before entering the routine and these
      !                indices are carried around during the sorting process
      !
      ! no work space needed !
      ! free us from machine-dependent sorting-routines !
      !
      ! adapted from Numerical Recipes pg. 329 (new edition)
      !
      IMPLICIT NONE
      !-input/output variables
      INTEGER :: n
      INTEGER :: ind (n)
      REAL(DP) :: ra (n)
      !-local variables
      INTEGER :: i, ir, j, l, iind
      REAL(DP) :: rra
      ! initialize index array
      IF (ind (1) ==0) THEN
         DO i = 1, n
            ind (i) = i
         ENDDO
      ENDIF
      ! nothing to order
      IF (n<2) RETURN
      ! initialize indices for hiring and retirement-promotion phase
      l = n / 2 + 1
      ir = n
10    CONTINUE
      ! still in hiring phase
      IF (l>1) THEN
         l = l - 1
         rra = ra (l)
         iind = ind (l)
         ! in retirement-promotion phase.
      ELSE
         ! clear a space at the end of the array
         rra = ra (ir)
         !
         iind = ind (ir)
         ! retire the top of the heap into it
         ra (ir) = ra (1)
         !
         ind (ir) = ind (1)
         ! decrease the size of the corporation
         ir = ir - 1
         ! done with the last promotion
         IF (ir==1) THEN
            ! the least competent worker at all !
            ra (1) = rra
            !
            ind (1) = iind
            RETURN
         ENDIF
      ENDIF
      ! wheter in hiring or promotion phase, we
      i = l
      ! set up to place rra in its proper level
      j = l + l
      !
      DO WHILE (j<=ir)
         IF (j<ir) THEN
            ! compare to better underling
            IF (ra (j) <ra (j + 1) ) THEN
               j = j + 1
            ELSEIF (ra (j) ==ra (j + 1) ) THEN
               IF (ind (j) <ind (j + 1) ) j = j + 1
            ENDIF
         ENDIF
         ! demote rra
         IF (rra<ra (j) ) THEN
            ra (i) = ra (j)
            ind (i) = ind (j)
            i = j
            j = j + j
         ELSEIF (rra==ra (j) ) THEN
            ! demote rra
            IF (iind<ind (j) ) THEN
               ra (i) = ra (j)
               ind (i) = ind (j)
               i = j
               j = j + j
            ELSE
               ! set j to terminate do-while loop
               j = ir + 1
            ENDIF
            ! this is the right place for rra
         ELSE
            ! set j to terminate do-while loop
            j = ir + 1
         ENDIF
      ENDDO
      ra (i) = rra
      ind (i) = iind
      GOTO 10
      !
    END SUBROUTINE hpsort

    SUBROUTINE sticks_deallocate
      IF( allocated( sticks_owner ) ) DEALLOCATE( sticks_owner )
      RETURN
    END SUBROUTINE sticks_deallocate


!=----------------------------------------------------------------------=
   END MODULE stick_base
!=----------------------------------------------------------------------=

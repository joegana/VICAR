C 2 JAN 95 ...CRI... MSTP S/W CONVERSION (VICAR PORTING)
C
      INCLUDE 'VICMAIN_FOR'
      SUBROUTINE MAIN44
C  IBIS ROUTINE IBISREGR
C
C  PURPOSE:  
C	IBISREGR PERFORMS A SERIES OF MULTIPLE REGRESSION ANALYSES
C       ON VARIOUS COMBINATIONS OF COLUMNS IN AN IBIS TABULAR FILE,
C       SEARCHING FOR OPTIMAL FITS.

C  THIS PROGRAM IS BASED ON PROGRAM 'IBISSTAT'

	IMPLICIT NONE

	INTEGER	MAXCOLLEN, MAXTOTLEN, MAXCOLS, MAXSOLNS
	PARAMETER( MAXCOLLEN = 500, MAXTOTLEN=10000, MAXCOLS=40)
	PARAMETER( MAXSOLNS = 20)

	INTEGER	UNIT, OUTUNIT, STATUS, COUNT, DEF, IBIS, OUTIBIS
	INTEGER	CLEN, NCOL, NINCOLS, MAXINCOLS, MININC, MAXINC
	INTEGER INCOLNO(MAXCOLS), INCOLS(MAXCOLS), TEMP(2)
	INTEGER BESTCOLS(MAXCOLS,MAXSOLNS), MBEST(MAXSOLNS)
	INTEGER	I, J, K, M, N, BUFPTR, DEPCOL, ERR, IPIV(MAXCOLS+1)
	INTEGER	NBEST, NBEST1, ICOL, JCOL

	REAL ALLDATA(MAXCOLLEN,MAXCOLS), OUTDATA(MAXCOLLEN)
	REAL DATA(MAXTOTLEN), DATA2(MAXTOTLEN)
	REAL RESID(MAXCOLLEN), BESTRES( MAXCOLLEN, MAXSOLNS)
	REAL DEPDATA(MAXCOLLEN), DEPDATA2(MAXCOLLEN), WORK(MAXTOTLEN)
	REAL BESTRSQ(MAXSOLNS), BESTSIG(MAXSOLNS)
	REAL SOLUTION(MAXCOLS+1), BESTSOL( MAXCOLS+1, MAXSOLNS)
	REAL INTERVALS(MAXCOLS+1), SSR, RSQUARED, SEE, EPSILON

	LOGICAL NOPRINT, XVPTST, EITHER, BOTH, RSONLY, SDONLY

	CHARACTER*8  COLNAMES(MAXCOLS), DEPNAME
	CHARACTER*80 STRING
	CHARACTER*16 FSTR,TMP1,TMP2

C---------------------------------------------------------------------
        CALL IFMESSAGE('IBISREGR version 2-JAN-95')
        CALL XVEACTION('SA',' ')

	NOPRINT = XVPTST( 'NOPRINT')
	BOTH = XVPTST( 'BOTH')
	EITHER = XVPTST( 'EITHER')
	RSONLY = XVPTST( 'RSQUARED')
	SDONLY = XVPTST( 'STDERR')
	
C		OPEN IBIS INTERFACE FILE
        CALL XVUNIT(UNIT, 'INP', 1, STATUS, ' ')

	CALL IBIS_FILE_OPEN(UNIT,IBIS,'READ',0,0,' ',' ',STATUS)
        IF (STATUS.NE.1) CALL IBIS_SIGNAL_U(UNIT,STATUS,1)
        CALL IBIS_FILE_GET(IBIS,'NC',NCOL,1,1)
        CALL IBIS_FILE_GET(IBIS,'NR',CLEN,1,1)

	N = CLEN
	IF (N .LT. 2)  CALL MABEND('COLUMN LENGTH TOO SHORT')
	IF (N .GT. MAXCOLLEN)  CALL MABEND('COLUMN LENGTH TOO LONG')

	CALL XVPARM( 'COLNAMES', COLNAMES, COUNT, DEF, MAXCOLS)
	DO I = COUNT+1, NCOL
	    IF (I.LE.9) THEN
		WRITE( COLNAMES(I), '(A6,I1)') 'COLUMN', I
	    ELSE
		WRITE( COLNAMES(I), '(A6,I2)') 'COLUMN', I
	    ENDIF
	ENDDO

C  GET THE DATA FOR THE DEPENDANT VARIABLE:
	CALL XVPARM( 'DEPCOL', DEPCOL, COUNT, DEF, 1)
	IF (COUNT.EQ.0) DEPCOL = NCOL
	CALL XVPARM( 'DEPNAME', DEPNAME, COUNT, DEF, 1)
	IF (COUNT.EQ.0) DEPNAME = COLNAMES(DEPCOL)
	CALL IBIS_COLUMN_READ(IBIS,DEPDATA,DEPCOL,1,CLEN,STATUS)
        IF (STATUS.NE.1) CALL IBIS_SIGNAL(IBIS,STATUS,1)

C  COLUMNS TO SEARCH THROUGH FOR INDEPENDENT VARIABLES:
	CALL XVPARM( 'COLS', INCOLNO, MAXINCOLS, DEF, MAXCOLS)
	IF (MAXINCOLS.EQ.0) THEN
	  MAXINCOLS = NCOL-1
	  J = 0
	  DO I = 1,NCOL
	    IF (I.NE.DEPCOL) THEN
	      J = J+1
	      INCOLNO(J) = I
	    ENDIF
	  ENDDO
	ENDIF

C  GET MINIMUM/MAXIMUM NUMBER OF COLUMN COMBINATIONS TO TRY:
	CALL XVPARM( 'COLRANGE', TEMP, COUNT, DEF, 2)
	IF (COUNT.EQ.0) THEN
	  MININC = 2
	  MAXINC = MAXINCOLS
        ELSE
	  MININC = TEMP(1)
	  MAXINC = TEMP(2)
	ENDIF
	IF (MAXINC.GT.MAXINCOLS) CALL MABEND('RANGE TOO HIGH')

	IF ((MAXINCOLS+1)*N .GT. MAXTOTLEN)  
     +			CALL MABEND('TOO MUCH DATA FOR BUFFER')
	IF (N .LT. MAXINC+1)  CALL MABEND('NOT ENOUGH ROWS OF DATA')

C  READ ALL THE COLUMN DATA TO BE SEARCHED INTO WORKING BUFFER:
	DO I = 1,MAXINCOLS
	   CALL IBIS_COLUMN_READ(IBIS,ALLDATA(1,I),INCOLNO(I),
     +                           1,N,STATUS)
           IF (STATUS.NE.1) CALL IBIS_SIGNAL(IBIS,STATUS,1)
	ENDDO

	CALL XVPARM( 'NBEST', NBEST, I, DEF, 1)
	IF (NBEST.GT.MAXSOLNS) CALL MABEND('NBEST TOO BIG')

	CALL XVMESSAGE('MULTIPLE REGRESSION SEARCH',' ')
	WRITE( STRING, '(2A)') 'DEPENDENT VARIABLE: ', DEPNAME
	CALL XVMESSAGE(STRING,' ')

C  START LOOPING OVER ALL POSSIBLE COMBINATIONS OF BETWEEN 'MININC'
C  AND 'MAXINC' COLUMNS.  WE MUST STORE THE 'NBEST' BEST SOLUTIONS.
	DO I = 1,NBEST
	  BESTRSQ(I) = -1.E30
	  BESTSIG(I) = 1.E30
	ENDDO

C  OUTERMOST LOOP IS OVER THE NUMBER OF COLUMNS, 'NINCOLS', WHICH VARIES
C   FROM 'MININC' TO 'MAXINC'.
C  THEN WE LOOP OVER THE COMBINATIONS OF COLUMNS, VARYING THE LAST
C   ONE MOST RAPIDLY AND THE FIRST ONE LEAST RAPIDLY.  (THIS CORRESPONDS
C   TO 'NINCOLS' EMBEDDED DO-LOOPS.)  

	NINCOLS = MININC
100	DO I = 1,NINCOLS			! BEGIN LOOP OVER # COLUMNS
	  INCOLS(I) = I
	ENDDO

C  BEGIN LOOP OVER COLUMNS:
C  PERFORM LEAST-SQS FIT FOR CURRENT 'INCOLS' COMBINATION:
200	IF (.NOT. NOPRINT) THEN
	  CALL XVMESSAGE(' ',' ')
	  WRITE( STRING, '(A6)') 'COLS: '
          J=7
     	  DO I=1,NINCOLS
	     WRITE(STRING(J+3*(I-1):J+3*(I-1)+2),'(I3)')
     *              INCOLNO(INCOLS(I))
          ENDDO
	  CALL XVMESSAGE(STRING,' ')
	ENDIF

	DO I = 1, N
	  DATA(I) = 1.0
	ENDDO
	DO I = 1, NINCOLS
	  BUFPTR = I*N + 1
	  CALL MVE( 7, N, ALLDATA(1,INCOLS(I)), DATA(BUFPTR),1,1)
	ENDDO
	M = NINCOLS + 1

	DO I = 1, N*M
	  DATA2(I) = DATA(I)
	ENDDO
	DO I = 1, N
	  DEPDATA2(I) = DEPDATA(I)
	ENDDO
	
	EPSILON = 1.0E-7
	CALL LLSQ( DATA2, DEPDATA2, N, M, 1,
     +			SOLUTION, IPIV, EPSILON, ERR, WORK)
	IF (ERR.NE.0) CALL MABEND('** COLUMNS ARE DEPENDENT **')
	SSR = WORK(1)

	CALL CALCRES( DATA, DEPDATA, SOLUTION, RESID, N, M, SSR)

	CALL REGSTAT (DATA, DEPDATA, N, M, SSR, SEE, RSQUARED, INTERVALS)

	IF (.NOT. NOPRINT) THEN
	  CALL XVMESSAGE(' ',' ')
	  WRITE (STRING, '(A)') 
     +			' VARIABLE     COEFFICIENT         ERROR'
	  CALL XVMESSAGE(STRING,' ')
          TMP1=FSTR(SOLUTION(1),12,6)
          TMP2=FSTR(INTERVALS(1),12,6)
	  WRITE (STRING, '(A,3X,A12,3X,A12)') '  CONSTANT', TMP1,TMP2
	  CALL XVMESSAGE(STRING,' ')
	  DO I = 2, M
             TMP1=FSTR(SOLUTION(I),12,6)
             TMP2=FSTR(INTERVALS(I),12,6)
	     WRITE (STRING, '(2X,A,3X,A12,3X,A12)') 
     +		    COLNAMES( INCOLNO(INCOLS(I-1))), TMP1,TMP2
	     CALL XVMESSAGE(STRING,' ')
	  ENDDO
	  CALL XVMESSAGE(' ',' ')
	  WRITE (STRING, '(A,F7.4)') 'R SQUARED = ', RSQUARED
	  CALL XVMESSAGE(STRING,' ')
          TMP1=FSTR(SEE,11,4)
	  WRITE (STRING, '(A,A11)') 'STD ERR OF EST = ', TMP1
	  CALL XVMESSAGE(STRING,' ')
	ENDIF

C  SEE IF THIS IS ONE OF THE 'NBEST' SOLUTIONS:
	DO I = 1,NBEST
	  IF ( (BOTH .AND. RSQUARED.GT.BESTRSQ(I) .AND. 
     &        SEE.LT.BESTSIG(I))
     &	  .OR. (EITHER .AND. (RSQUARED.GT.BESTRSQ(I) .OR.
     &	        SEE.LT.BESTSIG(I)))
     &	  .OR. (RSONLY .AND. RSQUARED.GT.BESTRSQ(I)) 
     &	  .OR. (SDONLY .AND. SEE.LT.BESTSIG(I))) THEN
	    GO TO 300
	  ENDIF
	ENDDO
	GO TO 310
300	DO J = NBEST,I+1,-1
	  BESTRSQ(J) = BESTRSQ(J-1)
	  BESTSIG(J) = BESTSIG(J-1)
	  MBEST(J) = MBEST(J-1)
	  CALL MVE( 4, NINCOLS, BESTCOLS(1,J-1), BESTCOLS(1,J),1,1)
	  CALL MVE( 7, NINCOLS+1, BESTSOL(1,J-1), BESTSOL(1,J),1,1)
	  CALL MVE( 7, N, BESTRES(1,J-1), BESTRES(1,J),1,1)
	ENDDO
	BESTRSQ(I) = RSQUARED
	BESTSIG(I) = SEE
	MBEST(I) = NINCOLS+1
	DO J = 1,NINCOLS
	  BESTCOLS(J,I) = INCOLNO( INCOLS(J))
	ENDDO
	DO J = 1,NINCOLS+1
	  BESTSOL(J,I) = SOLUTION(J)
	ENDDO
	CALL MVE( 7, N, RESID, BESTRES(1,I),1,1)

310	DO ICOL = NINCOLS,1,-1
	  IF (INCOLS(ICOL) .LT. MAXINCOLS-NINCOLS+ICOL) GO TO 400
	ENDDO
	GO TO 500		! END OF ALL COMBINATIONS OF CURRENT # COL'S

400	INCOLS(ICOL) = INCOLS(ICOL)+1
	DO JCOL = ICOL+1,NINCOLS
	  INCOLS(JCOL) = INCOLS(JCOL-1)+1
	ENDDO
	GO TO 200				! END LOOP OVER COLUMNS

500	NINCOLS = NINCOLS+1			! END LOOP OVER NUMBER OF COL'S
	IF (NINCOLS.LE.MAXINC) GO TO 100

C  OUTPUT THE 'NBEST' BEST SOLUTIONS TO DISK & TERMINAL:

C  FIRST CHECK THAT THERE WERE AT LEAST 'NBEST' SOLUTIONS:
	DO I = 1,NBEST
	  IF (BESTRSQ(I).GT.0.) NBEST1 = I
	ENDDO
	NBEST = NBEST1

	CALL XVPCNT( 'OUT', COUNT)
	IF (COUNT.GE.1) THEN
C  OPEN CORRECT SIZED IBIS OUTPUT FILE
           CALL XVUNIT(OUTUNIT, 'OUT', 1, STATUS, ' ')

	   CALL IBIS_FILE_OPEN(OUTUNIT,OUTIBIS,'WRITE',3*NBEST,N,
     *                         ' ',' ',STATUS)
           IF (STATUS.NE.1) CALL IBIS_SIGNAL_U(OUTUNIT,STATUS,1)

	   DO J = 1,NBEST
              CALL IBIS_COLUMN_SET(OUTIBIS,'FORMAT','FULL',3*J-2,STATUS)
              CALL IBIS_COLUMN_WRITE(OUTIBIS,BESTCOLS(1,J),3*J-2,
     +                       2,MBEST(J)+1,status)
              IF (STATUS.NE.1) CALL IBIS_SIGNAL(OUTIBIS,STATUS,1)
	      CALL ZIA( OUTDATA, MAXINC+1)
	      DO I = 1, MBEST(J)
	         OUTDATA(I) = BESTSOL(I,J)
	      ENDDO
              CALL IBIS_COLUMN_WRITE(OUTIBIS,OUTDATA,3*J-1,
     +                       1,MBEST(J),status)
              IF (STATUS.NE.1) CALL IBIS_SIGNAL(OUTIBIS,STATUS,1)
              CALL IBIS_COLUMN_WRITE(OUTIBIS,BESTRES(1,J),3*J,
     +                       1,N,status)
              IF (STATUS.NE.1) CALL IBIS_SIGNAL(OUTIBIS,STATUS,1)
	   ENDDO
	   CALL IBIS_FILE_CLOSE(OUTIBIS,' ',STATUS)
           IF (STATUS.NE.1) CALL IBIS_SIGNAL_U(OUTUNIT,STATUS,1)
	ENDIF

        CALL XVMESSAGE(' ',' ')
	CALL XVMESSAGE('BEST SOLUTIONS FOUND:',' ')

	DO J = 1,NBEST
	  CALL XVMESSAGE(' ',' ')
	  M = MBEST(J)-1
	  WRITE( STRING, '(A6)') 'COLS: '
          K=7
     	  DO I=1,M
	     WRITE(STRING(K+3*(I-1):K+3*(I-1)+2),'(I3)') BESTCOLS(I,J)
          ENDDO
	  CALL XVMESSAGE(STRING,' ')
          TMP1=FSTR(BESTSIG(J),11,4)
	  WRITE( STRING, '(A,F7.4,A,A11)') 'R SQUARED = ', BESTRSQ(J),
     &	   '  STD ERR = ', TMP1
	  CALL XVMESSAGE(STRING,' ')
	ENDDO

	CALL IBIS_FILE_CLOSE(IBIS,' ',STATUS)
        IF (STATUS.NE.1) CALL IBIS_SIGNAL_U(UNIT,STATUS,1)

	RETURN
	END




	CHARACTER*16 FUNCTION FSTR( VALUE, FIELDWIDTH, NDECIMALS)
	IMPLICIT NONE
	REAL	VALUE
	INTEGER	FIELDWIDTH, NDECIMALS

	IF ( ABS(VALUE) .GE. 10**(FIELDWIDTH-NDECIMALS-2) .OR. 
     +	    ( ABS(VALUE) .LT. 0.1**NDECIMALS .AND. VALUE .NE. 0.0) ) THEN
           IF (FIELDWIDTH .EQ. 11) THEN
	      WRITE( FSTR, '(E11.4)', ERR=100 )  VALUE
	   ELSE
	      WRITE( FSTR, '(E12.6)', ERR=100 )  VALUE
           END IF
	ELSE
           IF (FIELDWIDTH .EQ. 11) THEN
	      WRITE( FSTR, '(F11.4)', ERR=100 )  VALUE
	   ELSE
	      WRITE( FSTR, '(F12.6)', ERR=100 )  VALUE
           END IF
	ENDIF
	RETURN

100	FSTR = '****************'
	RETURN
	END



	SUBROUTINE REGSTAT(C, Y, N, M, SSR, SEE, RSQUARED, INTERVALS)
	IMPLICIT NONE
	INTEGER	N, M
	REAL	C(N,M), Y(N), SSR, SEE, RSQUARED, INTERVALS(M)
	INTEGER	I, J, K, L, ERR, WORK2(41), WORK3(41)
	REAL	A(41*41), SUM, EPS, WORK1(41)
	REAL	MEAN, SUMSQR


	SUM = 0.0
	DO I = 1, N
	    SUM = SUM + Y(I)
	ENDDO
	MEAN = SUM/N
	SUMSQR = 0.0
	DO I = 1, N
	    SUMSQR = SUMSQR + (Y(I) - MEAN)**2
	ENDDO
	RSQUARED = (SUMSQR - SSR) / SUMSQR
	SEE = SQRT(SSR/(N-M))


C		CALCULATE CONFIDENCE INTERVALS FOR THE REGRESSION COEFS
	L = 1
	DO J = 1, M
	    DO K = 1, M
		SUM = 0.0
		DO I = 1, N
		    SUM = SUM + C(I,J)*C(I,K)
		ENDDO
		A(L) = SUM
		L = L + 1
	    ENDDO
	ENDDO

	EPS = 1.0E-7
	CALL MINV (A, M, EPS, ERR, WORK1, WORK2, WORK3)
	IF (ERR .NE. 0) CALL MABEND ('SINGULAR MATRIX')

	DO K = 1, M
	    INTERVALS(K) = SEE*SQRT(A(K+M*(K-1)))
	ENDDO

	RETURN
	END


	SUBROUTINE CALCRES( A, B, X, RES, N, M, SSR)
	IMPLICIT NONE
	INTEGER	I,J,  N,M
	REAL	A(N,M), B(N), X(M), RES(N), SSR, SUM

	DO I = 1, N
	    SUM = B(I)
	    DO J = 1, M
		SUM = SUM - A(I,J)*X(J)
	    ENDDO
	    RES(I) = SUM
	ENDDO

	SSR = 0.0
	DO I = 1, N
	    SSR = SSR + RES(I)**2
	ENDDO

	RETURN
	END



      SUBROUTINE MINV( A,N,E,K,X,J2,I2)
C*     MATRIX INVERSION ROUTINE-FORMULATED BY E. G. CLAYTON
C
C      A--SQUARE ARRAY (SINGLE PRECISION) CONTAINING ORIGINAL MATRIX
C      N--ORDER OF ORIGINAL MATRIX
C      E--TEST CRITERION FOR NEAR ZERO DIVISOR
C      K--LOCATION FOR SINGULARITY OR ILL-CONDITION INDICATOR
C         K=0 =) MATRIX NONSINGULAR.
C         K=1 =) MATRIX SINGULAR (OR ILL-CONDITIONED)
C      X--A WORK VECTOR OF SIZE N
C      J2--AN INTEGER WORK VECTOR OF SIZE N
C      I2--AN INTEGER WORK VECTOR OF SIZE N
C
      DIMENSION A(N,N),X(N),J2(N),I2(N)
C
C     INITIALIZATION
C
      K=1
      I2(1)=0
      J2(1)=0
C
C     BEGIN COMPUTATION OF INVERSE
C
      DO 15 L=1,N
      L1=L-1
      IF(L1.EQ.0)L1=1
      BIGA=-1.0
C
C     LOOK FOR THE ELEMENT OF GREATEST ABSOLUTE VALUE,CHOOSING
C     ONE FROM A ROW AND COLUMN NOT PREVIOUSLY USED.
C
      DO 5 I=1,N
      DO 1 I3=1,L1
      IF(I .EQ. I2(I3))  GO TO 5
    1 CONTINUE
      DO 4 J=1,N
      DO 2 I3=1,L1
      IF(J .EQ. J2(I3))  GO TO 4
    2 CONTINUE
      AT=ABS(A(I,J))
      IF(BIGA .GE. AT)  GO TO 4
      BIGA=AT
      J1=J
      I1=I
    4 CONTINUE
    5 CONTINUE
C
C     TAG THE ROW AND COLUMN FROM WHICH THE ELEMENT IS CHOSEN.
C
      J2(L)=J1
      I2(L)=I1
      DIV=A(I1,J1)
C
C     TEST ELEMENT AGAINST ZERO CRITERION
      IF(ABS(DIV) .LE. E)  GO TO 221
C
C     PERFORM THE COMPUTATIONS
C
      OOD = 1./DIV
      DO 7 J=1,N
      A(I1,J)=A(I1,J)*OOD
    7 CONTINUE
      A(I1,J1)=OOD
      DO 11 I=1,N
      IF(I1 .EQ. I)  GO TO 11
      DO 10 J=1,N
      IF(J1 .EQ. J)  GO TO 10
      A(I,J)=A(I,J)-A(I1,J)*A(I,J1)
   10 CONTINUE
   11 CONTINUE
      DO 14 I=1,N
      IF(I1 .EQ. I)  GO TO 14
      A(I,J1)=-A(I,J1)*A(I1,J1)
   14 CONTINUE
   15 CONTINUE
C
C     COMPUTATION COMPLETE AT THIS POINT
C     UNSCRAMBLE THE INVERSE
C
      DO 18 J=1,N
      DO 16 I=1,N
      I1=I2(I)
      J1=J2(I)
      X(J1)=A(I1,J)
   16 CONTINUE
      DO 17 I=1,N
      A(I,J)=X(I)
17    CONTINUE
   18 CONTINUE
      DO 21 I=1,N
      DO 19 J=1,N
      I1=I2(J)
      J1=J2(J)
      X(I1)=A(I,J1)
   19 CONTINUE
      DO 20 J=1,N
      A(I,J)=X(J)
   20 CONTINUE
   21 CONTINUE
      K=0
  221 RETURN
      END

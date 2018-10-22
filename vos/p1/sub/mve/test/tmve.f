      INCLUDE 'VICMAIN_FOR'
      SUBROUTINE MAIN44
      DIMENSION BUF(32)
      DIMENSION BBUF(20),HBUF(20),FBUF(20),RBUF(20),DBUF(20)
      DIMENSION BBUG(10),HBUG(10),FBUG(10),RBUG(10),DBUG(10)
      BYTE BBUF,BBUG
      INTEGER*2 HBUF,HBUG
      INTEGER*4 FBUF,FBUG
      REAL*4 RBUF,RBUG
      REAL*8 DBUF,DBUG
C
      DO I=1,10
      IVAL = I - 5
      BBUF(I) = IVAL
      HBUF(I) = IVAL
      FBUF(I) = IVAL
      RBUF(I) = IVAL + 0.123412341234D0
      DBUF(I) = IVAL + 0.123412341234D0
      ENDDO
C      
      HBUF(9) = -32768
      HBUF(10) = 32767
      FBUF(7) = -32769
      FBUF(8) = -32768
      FBUF(9) = 32767
      FBUF(10) = 32768
C
      NS = 10
      CALL XVMESSAGE('Test #1:  AINC and BINC =1', ' ')
      CALL PRNT(1,NS,BBUF,' Initial BBUF=.')
      CALL PRNT(2,NS,HBUF,' Initial HBUF=.')
      CALL PRNT(4,NS,FBUF,' Initial FBUF=.')
      CALL PRNT(7,NS,RBUF,' Initial RBUF=.')
      CALL PRNT(8,NS,DBUF,' Initial DBUF=.')
      CALL MVE(-9,NS,DBUF,BUF,1,1)
      CALL PRNT(7,NS,BUF,' DCODE=-9.')
      CALL MVE(-8,NS,DBUF,BUF,1,1)
      CALL PRNT(8,NS,BUF,' DCODE=-8.')
      CALL MVE(-7,NS,RBUF,BUF,1,1)
      CALL PRNT(7,NS,BUF,' DCODE=-7.')
      CALL MVE(-6,NS,FBUF,BUF,1,1)
      CALL PRNT(2,NS,BUF,' DCODE=-6.')
      CALL MVE(-5,NS,FBUF,BUF,1,1)
      CALL PRNT(1,NS,BUF,' DCODE=-5.')
      CALL MVE(-4,NS,FBUF,BUF,1,1)
      CALL PRNT(4,NS,BUF,' DCODE=-4.')
      CALL MVE(-3,NS,HBUF,BUF,1,1)
      CALL PRNT(1,NS,BUF,' DCODE=-3.')
      CALL MVE(-2,NS,HBUF,BUF,1,1)
      CALL PRNT(2,NS,BUF,' DCODE=-2.')
      CALL MVE(-1,NS,BBUF,BUF,1,1)
      CALL PRNT(1,NS,BUF,' DCODE=-1.')
      CALL XVMESSAGE('MVE SHOULD PRINT ERROR MESSAGE FOR DCODE=0', ' ')
      CALL MVE(0,NS,BBUF,BUF,1,1)
      CALL MVE(1,NS,BBUF,BUF,1,1)
      CALL PRNT(1,NS,BUF,' DCODE=1.')
      CALL MVE(2,NS,HBUF,BUF,1,1)
      CALL PRNT(2,NS,BUF,' DCODE=2.')
      CALL MVE(3,NS,BBUF,BUF,1,1)
      CALL PRNT(2,NS,BUF,' DCODE=3.')
      CALL MVE(4,NS,FBUF,BUF,1,1)
      CALL PRNT(4,NS,BUF,' DCODE=4.')
      CALL MVE(5,NS,BBUF,BUF,1,1)
      CALL PRNT(4,NS,BUF,' DCODE=5.')
      CALL MVE(6,NS,HBUF,BUF,1,1)
      CALL PRNT(4,NS,BUF,' DCODE=6.')
      CALL MVE(7,NS,RBUF,BUF,1,1)
      CALL PRNT(7,NS,BUF,' DCODE=7.')
      CALL MVE(8,NS,DBUF,BUF,1,1)
      CALL PRNT(8,NS,BUF,' DCODE=8.')
      CALL MVE(9,NS,RBUF,BUF,1,1)
      CALL PRNT(8,NS,BUF,' DCODE=9.')
C
      DO I=1,20
      IVAL = I-1
      BBUF(I) = IVAL
      HBUF(I) = IVAL
      FBUF(I) = IVAL
      RBUF(I) = IVAL
      DBUF(I) = IVAL
      ENDDO
C      
      NS = 10
      CALL XVMESSAGE('Test #2:  AINC=2 and BINC=-1)', ' ')
      CALL PRNT(1,20,BBUF,' Initial BBUF=.')
      CALL PRNT(2,20,HBUF,' Initial HBUF=.')
      CALL PRNT(4,20,FBUF,' Initial FBUF=.')
      CALL PRNT(7,20,RBUF,' Initial RBUF=.')
      CALL PRNT(8,20,DBUF,' Initial DBUF=.')
      CALL MVE(-9,NS,DBUF,RBUG(10),2,-1)
      CALL PRNT(7,NS,RBUG,' DCODE=-9.')
      CALL MVE(-8,NS,DBUF,DBUG(10),2,-1)
      CALL PRNT(8,NS,DBUG,' DCODE=-8.')
      CALL MVE(-7,NS,RBUF,RBUG(10),2,-1)
      CALL PRNT(7,NS,RBUG,' DCODE=-7.')
      CALL MVE(-6,NS,FBUF,HBUG(10),2,-1)
      CALL PRNT(2,NS,HBUG,' DCODE=-6.')
      CALL MVE(-5,NS,FBUF,BBUG(10),2,-1)
      CALL PRNT(1,NS,BBUG,' DCODE=-5.')
      CALL MVE(-4,NS,FBUF,FBUG(10),2,-1)
      CALL PRNT(4,NS,FBUG,' DCODE=-4.')
      CALL MVE(-3,NS,HBUF,BBUG(10),2,-1)
      CALL PRNT(1,NS,BBUG,' DCODE=-3.')
      CALL MVE(-2,NS,HBUF,HBUG(10),2,-1)
      CALL PRNT(2,NS,HBUG,' DCODE=-2.')
      CALL MVE(-1,NS,BBUF,BBUG(10),2,-1)
      CALL PRNT(1,NS,BBUG,' DCODE=-1.')
      CALL MVE(0,NS,BBUF,BBUG(10),2,-1)
      CALL MVE(1,NS,BBUF,BBUG(10),2,-1)
      CALL PRNT(1,NS,BBUG,' DCODE=1.')
      CALL MVE(2,NS,HBUF,HBUG(10),2,-1)
      CALL PRNT(2,NS,HBUG,' DCODE=2.')
      CALL MVE(3,NS,BBUF,HBUG(10),2,-1)
      CALL PRNT(2,NS,HBUG,' DCODE=3.')
      CALL MVE(4,NS,FBUF,FBUG(10),2,-1)
      CALL PRNT(4,NS,FBUG,' DCODE=4.')
      CALL MVE(5,NS,BBUF,FBUG(10),2,-1)
      CALL PRNT(4,NS,FBUG,' DCODE=5.')
      CALL MVE(6,NS,HBUF,FBUG(10),2,-1)
      CALL PRNT(4,NS,FBUG,' DCODE=6.')
      CALL MVE(7,NS,RBUF,RBUG(10),2,-1)
      CALL PRNT(7,NS,RBUG,' DCODE=7.')
      CALL MVE(8,NS,DBUF,DBUG(10),2,-1)
      CALL PRNT(8,NS,DBUG,' DCODE=8.')
      CALL MVE(9,NS,RBUF,DBUG(10),2,-1)
      CALL PRNT(8,NS,DBUG,' DCODE=9.')

      CALL XVMESSAGE(
     . 'Repeat test cases in C to test C interface: zmve', ' ')

      call tzmve

      RETURN
      END
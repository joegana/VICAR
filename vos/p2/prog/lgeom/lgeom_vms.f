C SUBROUTINE TO GET PHYSICAL MEMORY SIZE
        SUBROUTINE GET_MEM_SIZE(MEMSIZE)
        INTEGER MEMSIZE,WSEXT,WSLIM,WSA ! WSA IS ADJUSTMENT FOR BUFFERS ETC 

	CALL XVPARM('WSA',WSA,I,K,0) ! GET WORKING SET ADJUSTMENT FOR BUFFERS

	WSEXT=0 ! INITIALIZE WSEXT
5	CALL SYS$ADJWSL(3000,WSLIM) ! TRY TO INCREASE WORKING SET
	IF(WSLIM.EQ.WSEXT) GOTO 10 ! IF NO CHANGE, GOTO 10
	WSEXT=WSLIM
	GOTO 5
10	MEMSIZE = WSEXT*512-WSA    !ALLOW WSA BYTES FOR BUFFERS ETC.
        RETURN
        END

C SUBROUTINE TO EXPLAIN WHY LGEOM CAN'T HANDLE IMAGE.
        SUBROUTINE TOOBIG
	CALL MABEND('** PICTURE IS TOO LARGE FOR THIS WORKING SET')
        RETURN
        END

C SUBROUTINE TO CHECK FOR SMALL PAGE FILE QUOTA UNDER VMS
        SUBROUTINE CHECK_VMS_PAGE_FILE_QUOTA
	INTEGER*4 RPFQ
	CALL GRPFQ(RPFQ) ! GET REMAINING PAGE FILE QUOTA
	IF(RPFQ.EQ.0) 
     .     CALL XVMESSAGE('PAGE FILE QUOTA MAY BE TOO SMALL',' ')
        RETURN
        END

C	GWSEXT - GET WORKING SET EXTENT (MAX PAGES OF MEMORY)
C	GRPFQ  - GET REMAINING PAGE FILE QUOTA

	SUBROUTINE GWSEXT(WSEXT)
	INTEGER*4 WSEXT,RPFQ
	INCLUDE '($JPIDEF)'
	CALL LIB$GETJPI(JPI$_WSEXTENT,,,WSEXT)
	RETURN

	ENTRY GRPFQ(RPFQ)
	CALL LIB$GETJPI(JPI$_PAGFILCNT,,,RPFQ)
	RETURN

	END


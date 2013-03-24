;################################################################
;#                          COPYRIGHT                           #
;################################################################
;
;   BRAULT          Francois
;   DE DIEULEVEULT  Etienne
;   LAHAYE          Vincent
;   LARTIGUE        Mederick
;
;                                   Projet ASM SUPINFO 2010 
;
;################################################################

org 100h

;################################################################
;#                        INIT REGISTRE                         #
;################################################################

MOV AX, 0B800h  ; On initialise le registre DS au debut de la memoire video
MOV DS, AX

MOV AX, 02000h
MOV ES, AX

;################################################################
;#                          COULEURS                            #
;################################################################
;
;      0000  black          0001  blue 
;      0010  green          0011  cyan 
;      0100  red            0101  magenta 
;      0110  brown          0111  light gray 
;      1000  dark gray      1001  light blue 
;      1010  light green    1011  light cyan 
;      1100  light red      1101  light magenta 
;      1110  yellow         1111  white
;
;                Background _ Foreground                            

MOV ES:[200h],0010_0010b ;color_back      
MOV ES:[201h],0000_0010b ;color_score
MOV ES:[202h],0000_0100b ;color_vie
MOV ES:[203h],0010_1110b ;color_bal
MOV ES:[204h],0010_0010b ;color_delbal
MOV ES:[205h],0100_0100b ;color_bX  
MOV ES:[206h],0001_0001b ;color_bY      
MOV ES:[207h],0111_0111b ;color_cX      
MOV ES:[208h],0111_0111b ;color_cY     
MOV ES:[209h],1111_1111b ;color_raq      
MOV ES:[20Ah],0010_0010b ;color_delraq 
MOV ES:[20Bh],0000_0010b ;color_win      
MOV ES:[20Ch],0000_0100b ;color_loose

;################################################################
;#                      INIT UNIQUE VARIABLE                    #
;################################################################

MOV ES:[024h],255 ;GlisseBalle     db 1 ; definit si la balle glisse sur la raquette au moment de l'impact avec la raquette
MOV ES:[026h],255 ;GlisseBalleDel  db 1
MOV ES:[028h],0   ;TouchCount      db 0
MOV ES:[02Ah],0   ;InversStart     db 0 ; 0 = Depart Haut Gauche - 255 = Depart Haut Droite
;################################################################
;#                         VISUEL FX SHOW                       #
;################################################################

CALL background

CALL cadre

;################################################################
;#                           START GAME                         #
;################################################################

StartGame:

;BriqueY [103h;117h]
MOV ES:[103h],1 
MOV ES:[104h],1
MOV ES:[105h],1
MOV ES:[106h],1
MOV ES:[107h],1
MOV ES:[108h],1
MOV ES:[109h],1
MOV ES:[10Ah],1
MOV ES:[10Bh],1
MOV ES:[10Ch],1
MOV ES:[10Dh],1
MOV ES:[10Eh],1
MOV ES:[10Fh],1
MOV ES:[110h],1
MOV ES:[111h],1
MOV ES:[112h],1
MOV ES:[113h],1
MOV ES:[114h],1
MOV ES:[115h],1
MOV ES:[116h],1
MOV ES:[117h],1

;BriqueX [11Eh;132h]
MOV ES:[11Eh],1 
MOV ES:[11Fh],1
MOV ES:[120h],1
MOV ES:[121h],1
MOV ES:[122h],1
MOV ES:[123h],1
MOV ES:[124h],1
MOV ES:[125h],1
MOV ES:[126h],1
MOV ES:[127h],1
MOV ES:[128h],1
MOV ES:[129h],1
MOV ES:[12Ah],1
MOV ES:[12Bh],1
MOV ES:[12Ch],1
MOV ES:[12Dh],1
MOV ES:[12Eh],1
MOV ES:[12Fh],1
MOV ES:[130h],1
MOV ES:[131h],1
MOV ES:[132h],1

MOV ES:[000h],0  ;scoreGlob dizaine       dw 0,"$"  ;[102h;105h]
MOV ES:[001h],0  ;scoreGlob centaine
MOV ES:[002h],3  ;vieGlob         dw 3,"$"  ;[106h;109h]

MOV ES:[008h],1  ;newPartie       db 1
MOV ES:[00Ah],1  ;newNiveau       db 1

MOV ES:[00Eh],38 ;posRaquette    db 38

CALL scoreInit

boucle:

    ; test si nouvelle partie
    CMP ES:[008h],0
    JE finTestPartie
    
        ; test si nouveau niveau
        CMP ES:[00Ah],0
        JE noNewNiveau
            
            ;on construit les brique
            CALL brique
            
            MOV ES:[00Ah],0 ;newNiveau       db 0
            MOV ES:[003h],0 ;statusWinLoose  0 = en cours - 1 = gagner - 2 = perdu
                         
        noNewNiveau:
   
        ;init var partie
        
        MOV ES:[004h],0 ;tmpRaquette     db 0     
        MOV ES:[006h],0 ;tmpPartie       db 0
        MOV ES:[008h],0 ;newPartie       db 0
        MOV ES:[02Ch],0 ;TouchStart      db 0 ; 0 = la balle n'a jamais toucher la raquette
        
        ;Init Balle Y
        
        MOV ES:[012h],0 ;balleSensY      db 0  ; 0 = Bas    | 255 = Haut
        MOV ES:[016h],0 ;balleDelSensY   db 0  ; 0 = Bas    | 255 = Haut
        MOV ES:[01Ah],2 ;balleDelY       db 2
        MOV ES:[01Eh],2 ;balleY          db 2
        
        ; on check le type de depart qu'il faut initialiser
        CMP ES:[02Ah],255
        JE departHD
            
            ;depart en Haut a Gauche
            
            ;Init Balle X
            MOV ES:[010h],0 ;balleSensX      db 0  ; 0 = Droite | 255 = Gauche
            MOV ES:[014h],0 ;balleDelSensX   db 0  ; 0 = Droite | 255 = Gauche
            MOV ES:[018h],1 ;balleDelX       db 1
            MOV ES:[01Ch],1 ;balleX          db 1
            
            ; le registre " SI " stock l'adresse memoire video de la nouvelle position de la balle
            MOV SI, 142h
            ; le registre " DI " stock l'adresse memoire video de la derniere position de la balle
            MOV DI, 142h
            
            JMP finChoixDep
        
        departHD:
            
            ;depart en Haut a Droite
            
            ;Init Balle X
            MOV ES:[010h],255 ;balleSensX      db 0  ; 0 = Droite | 255 = Gauche
            MOV ES:[014h],255 ;balleDelSensX   db 0  ; 0 = Droite | 255 = Gauche
            MOV ES:[018h],78  ;balleDelX       db 78
            MOV ES:[01Ch],78  ;balleX          db 78
            
            ; le registre " SI " stock l'adresse memoire video de la nouvelle position de la balle
            MOV SI, 1DCh
            ; le registre " DI " stock l'adresse memoire video de la derniere position de la balle
            MOV DI, 1DCh
              
        finChoixDep:
        
            ;inversse le prochain depart
            NOT ES:[02Ah]            
        
            ;on reinitialise la raquette
            CALL raquetteInit
    
    finTestPartie:
        
        CALL attenteClavier
        
        CALL deplaceBalle
             
        CALL attenteClavier
                
        CALL effaceBalle
        
        CMP ES:[003h],0
        JE boucle
        
            CMP ES:[003h],1
            JNE gameOver
            
                CALL fonctVictoire
                            
                JMP boucle    
            
            gameOver:
            
                CALL fonctDefaite
                
                JMP StartGame          
    
JMP boucle

findujeu:

MOV AH,4CH
INT 21h

RET


;################################################################
;#                            FIN MAIN                          #
;################################################################





;################################################################
;#                      PROCEDURE BACKGROUND                    #
;################################################################


background proc
    
    ;init affichage cadre haut
    MOV AH,13h
    MOV AL,1
    MOV BH,0 
    MOV CX,78
    MOV BL,ES:[200h]
    MOV DH,2
    MOV DL,1
    MOV BP,offset msgBack
    
    debutB:
        
        CMP DH,25
        JNB finB
        
        INT 10h
        INC DH
        
        JMP debutB
        
    finB:
    
    RET
    
    msgBack db "                                                                              $"
    
background endp

;################################################################
;#                       PROCEDURE CADRE                        #
;################################################################

cadre proc
    
    ;init affichage cadre haut    
    MOV BX, 0A0h         ; Debut colone 0 ligne 2    
    MOV CX, 80           ; 80 colonnes
    MOV DH, ES:[207h]
    MOV DL, 95
    
    ; on creer le cadre du horisontale du haut    
    debutH:
    
        MOV [BX], DX        
        ADD BX,2
        
    LOOP debutH
        

    ;init affichage cadre haut
    MOV BX, 00h             
    MOV CX, 23          ; 23 lignes
    MOV DH, ES:[208h]
    MOV DL, 73
    
    ; on creer le cadre vericale        
    debutV:
        
       MOV [0140h + BX], DX
       MOV [01DEh + BX], DX

       ADD BX,0A0h         
              
    LOOP debutV
    
    RET
  
cadre endp

;################################################################
;#                       PROCEDURE BRIQUE                       #
;################################################################

brique proc
    
    ;compteur brique
    MOV ES:[02Eh],0   ; CountBrique
    
    ; on affiche la brique + du milieu    
    MOV DH, ES:[205h]
    MOV DL, 32
    MOV [7D0h],DX

    ADD ES:[02Eh],4 ; la brique du milieur compte double
    
    ; on affiche les autre brique
    MOV CX, 0
    MOV SI, 0      
    debutL:

        CMP CX,20
        JE finBrique 
        
        MOV BX, CX
        MOV DH, ES:[205h]
        MOV DL, 45        
        MOV [7D2h + BX], DX ; Droite
            
        MOV BX, SI
        MOV DH, ES:[206h]
        MOV DL, 124
        MOV [870h + BX], DX ; Bas
        
        MOV BX, 7CEh
        SUB BX, CX
        MOV DH, ES:[205h]
        MOV DL, 45       
        MOV [BX], DX ; Gauche    

        MOV BX, 730h
        SUB BX, SI
        MOV DH, ES:[206h]
        MOV DL, 124
        MOV [BX], DX ; Haut

        ADD SI,0A0h
        ADD CX,2
        ADD ES:[02Eh],4  
    
    JMP debutL
    
    finBrique:
	
	RET

brique endp

;################################################################
;#                      PROCEDURES SCORE                        #
;################################################################

scoreInit proc
    
    MOV [00h], "S"
    MOV [02h], "c"
    MOV [04h], "o"
    MOV [06h], "r"
    MOV [08h], "e"
    MOV [0Ah], " "
    MOV [0Ch], ":"
    MOV [0Eh], " "
    MOV [10h], "0"
    MOV [12h], "0"
    MOV [14h], "0"
    
    ;Mise en couleur
    MOV DH, ES:[201h]
    MOV BX, 1
    MOV CX, 11
    
    scoreColor:    
        
        MOV [BX], DH
        ADD BX,2
        
    LOOP scoreColor
        
    MOV [20h], "V"
    MOV [22h], "i"
    MOV [24h], "e"
    MOV [26h], "s"
    MOV [28h], " "
    MOV [2Ah], ":"
    MOV [2Ch], " "
    MOV [2Eh], "3"
    
    ;Mise en couleur
    MOV DH, ES:[202h]
    MOV BX, 21h
    MOV CX, 8
    
    VieColor:
        
        MOV [BX], DH  
        ADD BX,2
        
    LOOP VieColor

    RET   
         
scoreInit endp

scoreUp proc

    ; incrementation du score + 10
    
    ;couleur
    MOV DH, ES:[201h]
    
    CMP ES:[0],8
    JLE upDizaine
        
        ;chiffre des centaines
        MOV ES:[0], 0
        INC ES:[1]       
        
        MOV DL, ES:[1]
        ADD DL, 30h
        
        MOV [10h], DX
        
        MOV DL, 30h        
        MOV [12h], DX 
        
        JMP finUpChiffre

    upDizaine:
        
        ; chiffre des dizaines
        INC ES:[0]
                
        MOV DL, ES:[0]
        ADD DL, 30h
        
        MOV [12h], DX
        
    finUpChiffre:
    
    CMP ES:[02Eh],0
    JNE finUpScore
    
        ;gagner
        MOV ES:[003h],1
    
    finUpScore:     

    RET   
    
scoreUp endp

vieUp proc
    
    ;mise a jour de l'affichage du nombre de vie
    MOV DH, ES:[202h]
    MOV DL, ES:[2]
    ADD DL, 30h
    MOV [2Eh],DX
    
    RET    
    
vieUp endp

;################################################################
;#                      PROCEDURE DEPLACEBALLE                  #
;################################################################

deplaceBalle proc
    
    ;affichage de la balle  
    MOV DH, ES:[203h]
    MOV DL, 15
    MOV [SI], DX   
        
    ; Test si balle sur brique Y
    
    ;if (ES:[01Ch] == 40)
    CMP ES:[01Ch],40        
    JE egalX
        JMP finBriqueY
    egalX:
        ;if (balleY > 2)
        CMP ES:[01Eh],2
        JG  supY            
            JMP finBriqueY
        supY:
            ;if (balleY < 25)
            CMP ES:[01Eh],25
            JLE infY
                JMP finBriqueY
            infY:
                ;creation de l'adresse memoire de la brique
                MOV BX,ES:[01Eh]
                ADD BX,100h
                ;if (briquesY[balleY] == 1)
                CMP ES:BX,1        
                JE unY
                    JMP finBriqueX
                unY:
                    ;enregistre la brique comme casser
                    MOV ES:BX,0
                    
                    ;decremente le nombre de brique restante
                    DEC ES:[02Eh]
                    
                    ; mise a jour du score                        
                    CALL scoreUp
                    
                    INC ES:[028h]
                    CMP ES:[028h],3
                    JNE suiteTouchS2
                
                        MOV ES:[028h],0
                        NOT ES:[024h]    
            
                    suiteTouchS2:
                    
                        NOT ES:[010h]
                        NOT ES:[014h] 
                                       
                    ; test si il s'agit de la brique + du milieu
                    ; inutile de tester les briques Y dans le cas contraire
                    ; et inutile de tester si la balle est sur la raquette
                    CMP ES:[01Eh],12        
                    JE  finBriqueY
                    
                        JMP finTestRaq                         
                         
        
    finBriqueY:
    
    ; Test si balle sur brique X
    
    ;if (balleY == 12)
    CMP ES:[01Eh],12        
    JE egalY
        JMP finBriqueX
    egalY:
        ;if (ES:[01Ch] > 29)
        CMP ES:[01Ch],29
        JG  supX            
            JMP finTestRaq
        supX:
            ;if (ES:[01Ch] < 51)
            CMP ES:[01Ch],51
            JLE infX
                JMP finTestRaq
            infX:
                ;creation de l'adresse memoire de la brique                
                MOV BX,ES:[01Ch]
                ADD BX,100h
                
                ;if (briquesX[balleX] == 1)
                CMP ES:BX,1     
                JE unX
                    JMP finTestRaq
                unX:
                    ;enregistre la brique comme casser
                    MOV ES:BX,0
                    
                    ;decremente le nombre de brique restante
                    DEC ES:[02Eh]
                    
                    ; mise a jour du score
                    CALL scoreUp
                    
                    INC ES:[028h]                
                    CMP ES:[028h],3
                    JNE suiteTouchS1
                
                        MOV ES:[028h],0
                        NOT ES:[024h]    
            
                    suiteTouchS1:
                    
                    
                    NOT ES:[012h]
                    NOT ES:[016h]
                        
                    JMP finTestRaq
        
    finBriqueX:
    
    
    ; Test si balle sur Raquette
    
        
    CMP ES:[004h],0
    JNE else3
    ;if (balleY == 23)
    CMP ES:[01Eh],23
    JNE else3
    
        MOV AL,ES:[00Eh]
        SUB AL,2
        MOV AH,ES:[00Eh]
        ADD AH,5
        
        ; if(balleX > AL) 
        CMP ES:[01Ch],AL
        JLE noRaq
            ; if(balleY <= AH)
            CMP ES:[01Ch],AH
            JG  noRaq
            
                MOV ES:[02Ch],1 ; informe que la balle a toucher au moins une fois la raquette
                
                ; la balle ne glisse plus sur la raquette toute les 3 touches durant 3 touches (brique,mur,raquette)
                ;TouchCount
                CMP ES:[024h],255
                JNE fin5a:
                
                ;if (ES:[010h] == 0)
                CMP ES:[010h],0
                JNZ else5
                
                    ;la balle va vers la droite
                    
                    ; Si la balle se deplace vers la droite et que la balle tombe 
                    ; sur la derniere position X de la raquette + 1
                    ; alors la balle ne touche pas la raquette 
                    ; si elle ce deplace vers la gauche alors elle touche la raquette
                    CMP ES:[01Ch],AH
                    JE  noRaq
                    
                    ; Si la balle se deplace vers la droite et que la balle tombe 
                    ; sur la derniere position X de la raquette
                    ; alors la balle ne glisse pas sur la raquette
                    DEC AH
                    CMP ES:[01Ch],AH
                    JE  noGlisse
                    
                        INC ES:[01Ch]
                        ADD SI,2
                        
                        JMP fin5
                    
                    noGlisse:
                        
                        MOV ES:[026h],0    

                    JMP fin5
                
                else5:
                
                    ;la balle va vers la gauche
                    
                    ; Si la balle se deplace vers la gauche et que la balle tombe 
                    ; sur la premiere position X de la raquette - 1
                    ; alors la balle ne touche pas la raquette 
                    ; si elle ce deplace vers la droite alors elle touche la raquette
                    CMP ES:[01Ch],AL
                    JE  noRaq
                    
                    ; Si la balle se deplace vers la droite et que la balle tombe 
                    ; sur la derniere position X de la raquette
                    ; alors la balle ne glisse pas sur la raquette
                    INC AL
                    CMP ES:[01Ch],AL
                    JE  noGlisse2
                    
                        DEC ES:[01Ch]
                        SUB SI,2
                        
                        JMP fin5
                    
                    noGlisse2:
                        
                        MOV ES:[026h],0         

                fin5a:
                
                    MOV ES:[026h],0
                    
                fin5:
                
                INC ES:[028h]
                
                CMP ES:[028h],3
                JNE suiteTouch
                
                    MOV ES:[028h],0
                    NOT ES:[024h]    
            
                suiteTouch:
                
                    MOV ES:[012h],255            
                    MOV ES:[004h],1 
            
                JMP fin4
            
        noRaq:
            ;tour suplementaire pour afficher la balle sur la ligne
            ;ou se trouve la raquette
            MOV ES:[006h],1
            CMP ES:[02Ch],1
            JNE finTestRaq
                
                CMP ES:[002h],0
                JE perdu 
                    
                    ; on enleve une vie
                    DEC ES:[002h]
                
                    CALL VieUp
                    
                    JMP finTestRaq
                    
                 perdu:
                    
                    MOV ES:[003h],2                  
                     
            JMP finTestRaq
    else3:
    
        MOV ES:[004h],0
        
        ;if (balleY == 24)    
        CMP ES:[01Eh],24
        JNE else3b
            ;new partie
            MOV ES:[008h],1
            
        else3b:
        
            ;if (balleY == 2)
            CMP ES:[01Eh],2
            JNE finTestRaq
            CMP ES:[012h],255
            JNE finTestRaq
                MOV ES:[012h],0
                
                INC ES:[028h]
                CMP ES:[028h],3
                JNE finTestRaq
                
                    MOV ES:[028h],0
                    NOT ES:[024h]
    
    finTestRaq:   
    
    ;if (ES:[012h] == 0)
    CMP ES:[012h],0
    JNZ else1
        ;la balle tombe
        INC ES:[01Eh]
        ADD SI,0A0h
    JMP fin1
    else1:
        ;la balle monte
        DEC ES:[01Eh]
        SUB SI,0A0h
    fin1: 
    
    ;if (ES:[010h] == 0)
    CMP ES:[010h],0
    JNZ else2
        ;la balle va vers la droite
        INC ES:[01Ch]
        ADD SI,2
    JMP fin2
    else2:
        ;la balle va vers la gauche
        DEC ES:[01Ch]
        SUB SI,2
    fin2:
    
    ;if (balleX == 78)    
    CMP ES:[01Ch],78
    JNZ else4
        MOV ES:[010h],255
        
        INC ES:[028h]
        CMP ES:[028h],3
        JNE fin4
                
            MOV ES:[028h],0
            NOT ES:[024h]
            JMP fin4
    else4:
    CMP ES:[01Ch],1
    JNZ fin4
        MOV ES:[010h],0
        
        INC ES:[028h]
        CMP ES:[028h],3
        JNE fin4
                
            MOV ES:[028h],0
            NOT ES:[024h]
    fin4:   
    
    RET   
    
deplaceBalle endp

;################################################################
;#                      PROCEDURE EFFACEBALLE                   #
;################################################################

effaceBalle proc
    
    ;sauvegarde DI
    MOV BX, DI
    
    ;if (balleY > 23)    
    CMP ES:[01Ah],23
    JNZ else_eb3
        CMP ES:[004h],1
        JNE fin_eb3 
            
            ;rebont raquette
            MOV ES:[016h],255
            JMP fin_eb1
        
        JMP fin_eb3
        
    else_eb3:
    
        CMP ES:[01Ah],2
        JNZ fin_eb3
            
            MOV ES:[016h],0 
        
    fin_eb3:
    
    ;if (balleX == 78)    
    CMP ES:[018h],78
    JNZ else_eb4
        
        MOV ES:[014h],255
        JMP fin_eb4
    
    else_eb4:
    
        CMP ES:[018h],1
        JNZ fin_eb4
        
            MOV ES:[014h],0
        
    fin_eb4:
    
    ;if (ES:[016h] == 0)
    CMP ES:[016h],0
    JNE else_eb1
        ;la balle tombe
        INC ES:[01Ah]
        ADD DI,0A0h
        JMP fin_eb1
        
    else_eb1:
    
        ;la balle monte
        DEC ES:[01Ah]
        SUB DI,0A0h
        
    fin_eb1: 
    
    CMP ES:[026h],255
    JNE else_eb2
        ;if (ES:[014h] == 0)
        CMP ES:[014h],0
        JNE else_eb2a
        
            ;la balle va vers la droite
            INC ES:[018h]
            ADD DI,2
            JMP fin_eb2
            
        else_eb2a:
        
            ;la balle va vers la gauche
            DEC ES:[018h]
            SUB DI,2
            JMP fin_eb2
            
    else_eb2:
    
        MOV ES:[026h],255
    
    fin_eb2:
    
    ;effacement de la balle  
    MOV DH, ES:[204h]
    MOV DL, 32
    MOV [BX], DX
    
    RET 
    
effaceBalle endp

;################################################################
;#                       PROCEDURES RAQUETTES                   #
;################################################################

raquetteInit proc

    ;efface la raquette si elle ne se trouve pas a la position initiale 38
    CMP ES:[00Eh], 38
    JE noEfface
    
        ; Calcul l'adresse memoire video de la premiere position de la raquette
        MOV BX,0F00h
        MOV CX,ES:[00Eh]
        ADD CX,CX ; x2
        ADD BX,CX
        
        MOV CX, 5
        MOV DH, ES:[20Ah]
        MOV DL, 32
        
        InitRaqEfface:
        
           MOV [BX], DX
           ADD BX,2 
        
        LOOP InitRaqEfface
        
    
    noEfface:    
    
    MOV BX, 0F4Ch 
    MOV CX, 5
    MOV DH, ES:[209h]
    MOV DL, 88
    
    RaqLoop:
    
        MOV [BX], DX
        ADD BX,2
    
    LOOP RaqLoop
    
    MOV ES:[00Ch],0  ;sensRaquette   db 0  ; 0 = Droite | 1 = Gauche
    MOV ES:[00Eh],38 ;posRaquette    db 38  

    RET
    
raquetteInit endp

raquetteMove proc
    
    ; Calcul la premiere position memoire
    MOV BX,0F00h
    MOV CX,ES:[00Eh]
    ADD CX,CX ; x2
    ADD BX,CX
    
    MOV DH, ES:[209h]
    MOV DL, 88 
    
    CMP ES:[00Ch],0
    JNE elseMove
        
        ;la raquette ce deplace de 1 pas a droite
        INC ES:[00Eh]    
        ADD BX, 0Ah
        MOV [BX], DX
        
        ;on efface a gauche la partie de la raquette qui a bouger
        SUB BX, 0Ah
        MOV DH, ES:[20Ah]
        MOV DL, 32
        
        MOV [BX], DX      
        
        JMP finMove
    
    elseMove:
    
        ;la raquette ce deplace de 1 pas a gauche
        DEC ES:[00Eh]
        SUB BX, 02h
        MOV [BX], DX

        ;on efface a droite la partie de la raquette qui a bouger 
        ADD BX, 0Ah
        MOV DH, ES:[20Ah]
        MOV DL, 32

        MOV [BX], DX
    
    finMove:

    RET
    
raquetteMove endp

;################################################################
;#                       PROCEDURE CLAVIER                      #
;################################################################

attenteClavier proc
        
    ;ES:[006h]    
    
    
    ;recuperation touche clavier
    MOV AH, 01H
    INT 16h    
    JNZ checkTouche

        JMP finAttenteClavier
    
    checkTouche:
    
            CMP AL,119 ; w
            JNE touchSuivant

                CMP ES:[00Eh],1
                JE delAttenteClavier
                
                CMP ES:[006h],1
                JE delAttenteClavier 
                 
                    MOV ES:[00Ch],1
                            
                    JMP upRaquette                 
            
            touchSuivant:
                
                CMP AL,120 ; x
                JNE delAttenteClavier
  
                    CMP ES:[00Eh],74
                    JE delAttenteClavier
                    
                    CMP ES:[006h],1
                    JE delAttenteClavier
                    
                        MOV ES:[00Ch],0 
 
                        JMP upRaquette
                        
            touchSuivant2:
            
                CMP AL,113 ; q
                JE  findujeu

            upRaquette:
        
                CALL raquetteMove
                
    
    delAttenteClavier:
    
        ; suppresion de toutes les touches en attentes
        MOV AH,0CH
        MOV AL,0
        INT 21h
    
    finAttenteClavier:
                     
    RET
            
attenteClavier endp

;################################################################
;#                       PROCEDURES MESSAGES                    #
;################################################################
                                        
fonctVictoire proc
    
    MOV AH,13h
    MOV AL,1
    MOV BH,0 
    MOV CX,40
    MOV BL,ES:[20Bh]
    MOV DH,11
    MOV DL,20
    MOV BP,offset victoireAffich1
    INT 10h

    INC DH
    MOV BP,offset victoireAffich2
    INT 10H
    
    INC DH
    MOV BP,offset victoireAffich3
    INT 10H
    
    ; reinitialise partie et niveau
    MOV ES:[008h],1
    MOV ES:[00Ah],1
            
    MOV AH,00h
    INT 16h
    
    CALL background

    RET
    
    victoireAffich1 db "########################################$"
    victoireAffich2 db "#           BRAVO, VICTOIRE !          #$"
    victoireAffich3 db "########################################$"
                                                                 
fonctVictoire endp

fonctDefaite proc
    
    MOV AH,13h
    MOV AL,1
    MOV BH,0 
    MOV CX,40
    MOV BL,ES:[20Ch]
    MOV DH,11
    MOV DL,20
    MOV BP,offset defaiteAffich1
    INT 10h

    INC DH
    MOV BP,offset defaiteAffich2
    INT 10H
    
    INC DH
    MOV BP,offset defaiteAffich3
    INT 10H
    
    ; reinitialise partie , niveau score et vie
    MOV ES:[008h],1
    MOV ES:[00Ah],1
            
    MOV AH,00h
    INT 16h
    
    CALL background 
    
    RET
    
    defaiteAffich1 db "########################################$"
    defaiteAffich2 db "#          DOMMAGE, DEFAITE !          #$"
    defaiteAffich3 db "########################################$" 
    
fonctDefaite endp
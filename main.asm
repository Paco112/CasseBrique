;################################################################
;#                          COPYRIGHT                           #
;################################################################
;
;   BRAULT Francois ( 93352 )
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

MOV ES:[000h],0010_0111b ;color_back ; no background = 0000_0111b
MOV ES:[002h],0010_1110b ;color_bal
MOV ES:[004h],0100_0100b ;color_bX  
MOV ES:[006h],0001_0001b ;color_bY      
MOV ES:[008h],0111_0111b ;color_cX      
MOV ES:[010h],0001_0001b ;color_cY   

;################################################################
;#                             VISUEL                           #
;################################################################

CMP ES:[000h],0000_0111b
JE noBG 
    CALL background
noBG:

CALL cadre

CALL brique

;################################################################
;#                           START GAME                         #
;################################################################

StartGame:
  
MOV ES:[014h],0 ; PAUSE      ; 0 = Continue | 255 = Pause
MOV ES:[016h],0 ; Brique Dynamique ; 0 = Non | 255 = On pose le nombre de brique de ES:[018h] 
MOV ES:[018h],10
MOV ES:[020h],3 ; Nombres de balles 

; Balle1
MOV ES:[100h],0144h
MOV ES:[102h],0     ; balleSensX ; 0 = Droite | 255 = Gauche
MOV ES:[104h],0     ; balleSensY ; 0 = Bas    | 255 = Haut

; Balle2
MOV ES:[110h],031Ah
MOV ES:[112h],255    ; balleSensX ; 0 = Droite | 255 = Gauche
MOV ES:[114h],0      ; balleSensY ; 0 = Bas    | 255 = Haut

; Balle3
MOV ES:[120h],0C6Ch
MOV ES:[122h],255    ; balleSensX ; 0 = Droite | 255 = Gauche
MOV ES:[124h],255    ; balleSensY ; 0 = Bas    | 255 = Haut  


boucle:

    MOV CX,ES:[020h]
    MOV DI,0
    
    nbBalle:
    
        MOV SI,ES:[100h + DI]
        
        CMP ES:[014h],0
        JNE attClavier
        
            CALL deplaceBalle
            
        attClavier:
    
            CALL attenteClavier
            
        MOV ES:[100h + DI],SI
            
        ADD DI,010h ; 10h = distance adresse memoire entre 2 balles
    
    LOOP nbBalle        
            
JMP boucle

findujeu:

MOV AH,4CH
INT 21h

RET

;################################################################
;#                      PROCEDURE BACKGROUND                    #
;################################################################

background proc    
       
    MOV DH,ES:[0]
    MOV DL,0
    
    MOV BX,0
    MOV CX,1000
    
    MOV SI,0F9Eh ; derniere case
    
    BGloop:
            
        MOV [BX],DX        
        MOV [SI],DX
        
        ADD BX,2
        SUB SI,2
                
    LOOP BGloop 
    
    RET
    
background endp

;################################################################
;#                       PROCEDURE CADRE                        #
;################################################################

cadre proc
    
    ;init affichage cadre haut    
    MOV BX, 00h         ; Debut colone 0 ligne 2    
    MOV CX, 80         ; 80 colonnes
    MOV DH, ES:[008h]
    MOV DL, 95
    
    ; on creer le cadre du horisontale du haut    
    debutH:
    
        MOV [BX], DX
        MOV [0F00h + BX], DX        
        ADD BX,2
        
    LOOP debutH
        

    ;init affichage cadre haut
    MOV BX, 00h             
    MOV CX, 23          ; 23 lignes
    MOV DH, ES:[010h]
    MOV DL, 73
    
    ; on creer le cadre vericale        
    debutV:
        
       MOV [0A0h + BX], DX
       MOV [13Eh + BX], DX

       ADD BX,0A0h         
              
    LOOP debutV
    
    RET
  
cadre endp

;################################################################
;#                       PROCEDURE BRIQUE                       #
;################################################################

brique proc
    
       
    ; on affiche la brique + du milieu    
    MOV DH, ES:[004h]
    MOV DL, 0
    MOV [7D0h],DX
    
    ; on affiche les autre brique
    MOV CX, 0
    MOV SI, 0      
    debutL:

        CMP CX,14
        JE finBrique 
        
        MOV BX, CX
        MOV DH, ES:[004h]
        MOV DL, 0        
        MOV [7D2h + BX], DX ; Droite
        
        MOV BX, 7CEh
        SUB BX, CX
        ;MOV DH, ES:[004h]
        ;MOV DL, 45       
        MOV [BX], DX ; Gauche
            
        MOV BX, SI
        MOV DH, ES:[006h]
        MOV DL, 0
        MOV [870h + BX], DX ; Bas

        MOV BX, 730h
        SUB BX, SI
        ;MOV DH, ES:[006h]
        ;MOV DL, 124
        MOV [BX], DX ; Haut

        ADD SI,0A0h
        ADD CX,2 
    
    JMP debutL
    
    finBrique:
	
	RET

brique endp

addBrique proc
    
    PUSH BX
    PUSH CX
    
    MOV CX,ES:[018h]    
    
    MOV DH, ES:[004h]
    MOV DL, 0
    
    MOV BX,SI
    addB:
    
        MOV [BX], DX
        
        CMP ES:[102h + DI],0
        JNE elseadd
            ADD BX,2
            JMP finadd
        elseadd:
            SUB BX,2
        finadd:
    
    LOOP addB 
    
    POP CX
    POP BX
    
addBrique endp


;################################################################
;#                      PROCEDURE DEPLACEBALLE                  #
;################################################################

deplaceBalle proc
    
    ; sauvegarde de la position actuelle de balle SI
    MOV BX,SI
    ;MOV CX,SI
    
    CMP ES:[102h + DI],0
    JNE elseb1
        ;la balle va vers la droite
        ADD BX,2
        JMP endb1
    elseb1:
        ;la balle va vers la gauche
        SUB BX,2
    endb1:
    
    CMP ES:[104h + DI],0
    JNE elseb2
        ;la balle va vers le bas
        ADD BX,0A0h
        JMP endb2
    elseb2:
        ;la balle va vers le haut
        SUB BX,0A0h
    endb2:    
    
    ; Test Couleur pour savoir si la balle doit rebonduire et dans quelle sens
    MOV AX, [BX]
    
    ; test si on est dans le vide ( couleur backgroud )
    CMP AH,ES:[0]
    JE norebont
        ; test pour savoir dans quelle sens rebondire
        CMP AH,ES:[006h]
        JNE rebontV
            NOT ES:[102h + DI]
            JMP endmove    
        rebontV:
            NOT ES:[104h + DI]
            JMP endmove    
    norebont:
    
    ; Ajout Brique Dynamique     
    CMP ES:[016h],0
    JE noAdd
        NOT ES:[016h] 
        CALL addBrique        
    noAdd:
    
    ; effacement de la trace    
    MOV DH,ES:[0]    
    MOV DL,0
    MOV [SI], DX
    
    ; on applique la novelle position de la balle
    MOV SI,BX
    
    ;affichage de la nouvelle position de la balle  
    MOV DH, ES:[002h]
    MOV DL, 15
    MOV [SI], DX        
        
    endmove:   
    
    RET   
    
deplaceBalle endp

addBalle proc
        
    PUSH AX
    PUSH BX
    PUSH CX   
    
    MOV CX, ES:[020h]
    
    INC ES:[020h]
    
        
    MOV BX, 0
    
    loopAddr:
    
       ADD BX, 010h 
    
    LOOP loopAddr    
   
    MOV AX, ES:[100h + DI] 
    MOV ES:[100h + BX], AX
    
    MOV AX, ES:[102h + DI]
    NOT AX
    MOV ES:[102h + BX], AX
    
    MOV AX, ES:[104h + DI]
    ;NOT AX
    MOV ES:[104h + BX], AX
    
    finaddB:
    
    POP CX
    POP BX
    POP AX
    
    RET
    
addBalle endp


;################################################################
;#                       PROCEDURE CLAVIER                      #
;################################################################

attenteClavier proc   
    
    
    ;recuperation touche clavier
    MOV AH, 01H
    INT 16h    
    JNZ checkTouche

        JMP finAttenteClavier
    
    checkTouche:
    
        CMP AL,112 ; p
        JNE toucheS

            NOT ES:[014h]
            JMP delClavier
            
        toucheS:
        
            CMP AL,98 ; b
            JNE toucheS2
            
               NOT ES:[016h]
               JMP delClavier 
            
        toucheS2:
        
            CMP AL,110 ; n
            JNE toucheS3
            
                CMP ES:[020h],0BEh ;190
                JNBE delClavier
                    
                    CALL addBalle
                
                JMP delClavier
            
        toucheS3:
        
            CMP AL,113 ; q
            JNE toucheS4
            
                JMP findujeu 
                
        toucheS4:               
            
        delClavier:
    
            ; suppresion de toutes les touches en attentes
            MOV AH,0CH
            MOV AL,0
            INT 21h
    
    finAttenteClavier:
                     
    RET
            
attenteClavier endp
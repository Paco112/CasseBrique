;################################################################
;#                          COPYRIGHT                           #
;################################################################
;
;   BRAULT          Francois
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
MOV ES:[208h],0001_0001b ;color_cY     
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

CALL brique

;################################################################
;#                           START GAME                         #
;################################################################

StartGame:

   
MOV ES:[010h],0 ; balleSensX ; 0 = Droite | 255 = Gauche
MOV ES:[012h],0 ; balleSensY ; 0 = Bas    | 255 = Haut
MOV ES:[014h],0 ; PAUSE      ; 0 = Continue | 255 = Pause
MOV ES:[016h],0 ; Brique Dynamique ; 0 = Non | 255 = On pose le nombre de brique de ES:[018h] 
MOV ES:[018h],10

; le registre " SI " stock l'adresse memoire video de la balle
MOV SI, 142h

boucle:    
        
    
    CMP ES:[014h],0
    JNE attClavier:
        
        CALL deplaceBalle
        
    attClavier:
    
        CALL attenteClavier        
            
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
       
    MOV DH,ES:[200h]
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
    MOV DH, ES:[207h]
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
    MOV DH, ES:[208h]
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
    MOV DH, ES:[205h]
    MOV DL, 0
    MOV [7D0h],DX
    
    ; on affiche les autre brique
    MOV CX, 0
    MOV SI, 0      
    debutL:

        CMP CX,14
        JE finBrique 
        
        MOV BX, CX
        MOV DH, ES:[205h]
        MOV DL, 0        
        MOV [7D2h + BX], DX ; Droite
        
        MOV BX, 7CEh
        SUB BX, CX
        ;MOV DH, ES:[205h]
        ;MOV DL, 45       
        MOV [BX], DX ; Gauche
            
        MOV BX, SI
        MOV DH, ES:[206h]
        MOV DL, 0
        MOV [870h + BX], DX ; Bas
        
            

        MOV BX, 730h
        SUB BX, SI
        ;MOV DH, ES:[206h]
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
    
    MOV CX,ES:[018h]    
    
    MOV DH, ES:[205h]
    MOV DL, 0
    
    MOV BX,SI
    addB:
    
        MOV [BX], DX
        
        CMP ES:[010h],0
        JNE elseadd
            ADD BX,2
            JMP finadd
        elseadd:
            SUB BX,2
        finadd:
    
    LOOP addB 
    
    POP BX
    
addBrique endp


;################################################################
;#                      PROCEDURE DEPLACEBALLE                  #
;################################################################

deplaceBalle proc
    
    ; sauvegarde de la position de balle SI
    MOV BX,SI
    MOV CX,SI
    
    CMP ES:[010h],0
    JNE elseb1
        ;la balle va vers la droite
        ADD BX,2
        JMP endb1
    elseb1:
        ;la balle va vers la gauche
        SUB BX,2
    endb1:
    
    CMP ES:[012h],0
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
    CMP AH,ES:[200h]
    JE norebont
        ; test pour savoir dans quelle sens rebondire
        CMP AH,ES:[206h]
        JNE rebontV
            NOT ES:[010h]
            JMP endmove    
        rebontV:
            NOT ES:[012h] 
            JMP endmove    
    norebont:
    
    ; Ajout Brique Dynamique     
    CMP ES:[016h],0
    JE noAdd:
        NOT ES:[016h] 
        CALL addBrique        
    noAdd:
    
    ; effacement de la trace
    MOV DH,ES:[200h]    
    MOV DL,0
    MOV [SI], DX   
    
    ; on applique la novelle position de la balle
    MOV SI,BX
    
    ;affichage de la nouvelle position de la balle  
    MOV DH, ES:[203h]
    MOV DL, 15
    MOV [SI], DX        
        
    endmove:   
    
    RET   
    
deplaceBalle endp


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
    
        CMP AL,112 ; p
        JNE toucheS

            NOT ES:[014h]
            
        toucheS:
        
            CMP AL,98 ; b
            JNE toucheS2
            
               NOT ES:[016h] 
            
        toucheS2:                 
            
        delAttenteClavier:
    
            ; suppresion de toutes les touches en attentes
            MOV AH,0CH
            MOV AL,0
            INT 21h
    
    finAttenteClavier:
                     
    RET
            
attenteClavier endp
% #####################################################
% IGT implemented by M.Vissani @2018
%
% This script based on Psychootolbox implements the original
% IGT in Bechara 1996.
% ######################################################
%



%Set file directory info
fs = filesep;
base_dir = '/Volumes/USB DISK/Behavior parkinson/IGT'; %for use on Matteo's computer
%Change to data directory if it exists, if not exist, then create it and cd
cd(base_dir);
if ~exist([base_dir fs 'Data'],'dir')
    mkdir([base_dir fs 'Data'])
end

%Load graphics for card image
I_back = imread([base_dir fs 'playing-card-back.jpg']);
I_fronte = imread([base_dir fs 'playing-card-fronte.jpg']);
%Create participant name
dat.time=fix(clock);
dat.subjectname = input('Enter subject''s ID: ','s');
if isempty(dat.subjectname)
    dat.subjectname = 'test';
end

%Create filename and open text file
dat.filename = sprintf('ExpIOWA-%s-%4d_%2d_%2d_%2d_%2d_%2d',dat.subjectname,dat.time(1)...
    ,dat.time(2),dat.time(3),dat.time(4),dat.time(5),dat.time(6));
fid = fopen(['Data' fs dat.filename, '.txt'], 'wt');

%Set some standard colors and text spacing/size parameters
white = [255 255 255];
black = [0 0 0];
red   = [255 0 0];
green = [0 255 0];
blue  = [0 0 255];

vSpacing = 1.5;
wrap = 80;
fontSize = 20;

%Text for instructuon screen
inst01 = [];
waitframes = 1;
%Number of trials
ntrials = 10;

%This is how much each deck always wins
A_win  = 100;
B_win  = 100;
C_win  = 50;
D_win  = 50;

%This sets up the lose structure for each deck (randomized within deck
%every ten times that deck is chosen
A_lose = [1250 0 0 0 0 0 0 0 0 0];
B_lose = [150 350 250 300 200 0 0 0 0 0];
C_lose = [50 50 50 50 0 0 0 0 0 0];
D_lose = [250 0 0 0 0 0 0 0 0 0 0];

%Each deck is given ntrials possible amounts to lose in a ntrials/10 x ntrials/10 structure
for i = 1:fix(ntrials/10)
    A_loseRand(1:10,i) = A_lose(randperm(10));
    B_loseRand(1:10,i) = B_lose(randperm(10));
    C_loseRand(1:10,i) = C_lose(randperm(10));
    D_loseRand(1:10,i) = D_lose(randperm(10));
end

%Converts 10x10 double of losing amounts to a 100x1 double
A_loseRand = A_loseRand( : );
B_loseRand = B_loseRand( : );
C_loseRand = C_loseRand( : );
D_loseRand = D_loseRand( : );

%Initialize the counter for number of times each card has been selected
A_counter = 0;
B_counter = 0;
C_counter = 0;
D_counter = 0;

initBank = 2000;        %Start with 2000 credits
currTot = initBank;     %Initialize current toal
allCurrTot(1,:) = 2000; %Maintain a vector of current total state
try % try is the only way to debug code with this toolbox
    Screen('Preference', 'SkipSyncTests', 1); % important for Mac
    ListenChar(0);
    
    %Prepare sound
    wavfilename = 'SlotMachine_payout_2s.wav';
    % Read WAV file from filesystem:
    [y, freq] = psychwavread(['Data' fs wavfilename]);
    wavedata = y';
    nrchannels = size(wavedata,1); % Number of rows == number of channels.
    
    %Make sure we have always 2 channels stereo output.
    if nrchannels < 2
        wavedata = [wavedata ; wavedata];
    end
    %Check sound driver
    InitializePsychSound(1);
    %Open Sound Buffer
    pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);
    %Set Volume
    PsychPortAudio('Volume', pahandle, 1);
    %Fill buffer
    PsychPortAudio('FillBuffer', pahandle, wavedata);
    repetitions=1;
    
    
    %Initialize window pointer and parameters
    [wPtr, rect] = Screen('OpenWindow',0);
    tex=Screen('MakeTexture', wPtr, I_back);
    tex_fronte=Screen('MakeTexture', wPtr, I_fronte);
    Screen(wPtr,'TextFont','Tahoma');
    Screen(wPtr,'TextStyle',0);
    Screen(wPtr,'TextSize',fontSize);
    %Query the frame duration
    ifi = Screen('GetFlipInterval', wPtr);
    %Create and show 'ready' screen, then wait for keyboard response
    Screen('FillRect',wPtr,white,rect);
    Screen(wPtr,'TextSize',40);
    DrawFormattedText(wPtr,'Inizio Esperimento','center','center',black);
    Screen('Flip',wPtr);
    KbWait([], 2);
    
    %Show a loading screen while creating graphics
    Screen('FillRect',wPtr,white,rect);
    Screen(wPtr,'TextSize',40);
    DrawFormattedText(wPtr,'Caricamento','center','center',black);
    Screen('Flip',wPtr);
    
    %Configure how screen space is drawn (creates a grid for drawing things)
    hGrid = linspace(rect(1),rect(3),100);
    vGrid = linspace(rect(2),rect(4),100);
    rect_A =      [hGrid(13) vGrid(20) hGrid(27) vGrid(55)];
    rect_B =      [hGrid(33) vGrid(20) hGrid(47) vGrid(55)];
    rect_C =      [hGrid(53) vGrid(20) hGrid(67) vGrid(55)];
    rect_D =      [hGrid(73) vGrid(20) hGrid(87) vGrid(55)];
    rect_submit = [hGrid(40) vGrid(80) hGrid(60) vGrid(90)];
    
    %Cards grow on-screen when moused-over
    grow = 30;
    
    %Graphics for larger versions of cards
    rect_A2 =     [rect_A(1)-grow rect_A(2)-grow rect_A(3)+grow rect_A(4)+grow];
    rect_B2 =     [rect_B(1)-grow rect_B(2)-grow rect_B(3)+grow rect_B(4)+grow];
    rect_C2 =     [rect_C(1)-grow rect_C(2)-grow rect_C(3)+grow rect_C(4)+grow];
    rect_D2 =     [rect_D(1)-grow rect_D(2)-grow rect_D(3)+grow rect_D(4)+grow];
    
    % [x,y,buttons] = GetMouse(wPtr);
    Screen(wPtr,'TextSize',40);
    DrawFormattedText(wPtr,'Istruzioni','center',hGrid(6),black);
    
    Screen('TextFont',wPtr, 'Arial');
    Screen('TextSize',wPtr, 40);
    fid_ist = fopen(['Data', fs 'instruction_text.txt'], 'rt');
    mytext = '';
    tline = fgets(fid_ist);
    while ischar(tline)
        tline = fgets(fid_ist);
        mytext = [mytext, tline];
    end
    fclose(fid_ist);
    DrawFormattedText(wPtr, mytext, vGrid(4), hGrid(13), 0, 85);
    DrawFormattedText(wPtr,'Premi un tasto qualunque per continuare.','center',vGrid(93),black);
    
    Screen('Flip',wPtr);
    KbWait([], 2);
    
    % draw static letter images below cards
    Screen(wPtr,'TextSize',40);
    DrawFormattedText(wPtr,'Esempio disposizione carte','center',hGrid(6),black);
    Screen(wPtr,'TextSize',40);
    Screen('DrawTexture', wPtr, tex,[],rect_A);
    Screen('DrawText',wPtr,'A',(rect_A(1) + rect_A(3))/2,((rect_A(2) + rect_A(4))/2)+200,black);
    
    Screen('DrawTexture', wPtr, tex,[],rect_B);
    Screen('DrawText',wPtr,'B',(rect_B(1) + rect_B(3))/2,((rect_B(2) + rect_B(4))/2)+200,black);
    
    Screen('DrawTexture', wPtr, tex,[],rect_C);
    Screen('DrawText',wPtr,'C',(rect_C(1) + rect_C(3))/2,((rect_C(2) + rect_C(4))/2)+200,black);
    
    Screen('DrawTexture', wPtr, tex,[],rect_D);
    Screen('DrawText',wPtr,'D',(rect_D(1) + rect_D(3))/2,((rect_D(2) + rect_D(4))/2)+200,black);
    
    Screen('TextSize',wPtr, 40);
    
    DrawFormattedText(wPtr,inst01,vGrid(15),hGrid(43),black,170,[],[],1.5);
    DrawFormattedText(wPtr,'Premi un tasto qualunque per continuare.','center',vGrid(93),black);
    
    Screen('Flip',wPtr);
    KbWait([], 2);
    
    %Show a loading screen while creating graphics
    Screen('FillRect',wPtr,white,rect);
    DrawFormattedText(wPtr,'Caricamento','center','center',black);
    vbl = Screen('Flip',wPtr);
    number_cards = 0;
    for i = 1:ntrials
        allStart = GetSecs;
        card = 0;
        A_counter = A_counter + 1;
        B_counter = B_counter + 1;
        C_counter = C_counter + 1;
        D_counter = D_counter + 1;
        
        while 1
            [x,y,buttons] = GetMouse(wPtr);
            Screen(wPtr,'TextSize',40);
            DrawFormattedText(wPtr,['Totale corrente: ' num2str(currTot),' Euro'],rect_submit(4) + 90 ,hGrid(55),red);
            Screen(wPtr,'TextSize',40);
            DrawFormattedText(wPtr,['Carte Pescate: ' num2str(number_cards)],rect_submit(1) - 450 ,hGrid(55),black);
            %         DrawFormattedText(wPtr,num2str(i),'center',hGrid(8),black);        %displays round number (for testing
            % display winnings of previous round
            if i > 1
                DrawFormattedText(wPtr,['Totale precedente: ' num2str(allCurrTot(i-1)),' Euro'],rect_submit(4) + 90,hGrid(58),blue);
                Screen(wPtr,'TextSize',35);
                
            end
            
            Screen(wPtr,'TextSize',40);
            
            % draw static letter images below cards
            Screen('DrawTexture', wPtr, tex,[],rect_A);
            Screen('DrawText',wPtr,'A',(rect_A(1) + rect_A(3))/2,((rect_A(2) + rect_A(4))/2)+250,black);
            
            Screen('DrawTexture', wPtr, tex,[],rect_B);
            Screen('DrawText',wPtr,'B',(rect_B(1) + rect_B(3))/2,((rect_B(2) + rect_B(4))/2)+250,black);
            
            Screen('DrawTexture', wPtr, tex,[],rect_C);
            Screen('DrawText',wPtr,'C',(rect_C(1) + rect_C(3))/2,((rect_C(2) + rect_C(4))/2)+250,black);
            
            Screen('DrawTexture', wPtr, tex,[],rect_D);
            Screen('DrawText',wPtr,'D',(rect_D(1) + rect_D(3))/2,((rect_D(2) + rect_D(4))/2)+250,black);
            
            Screen('FrameRect', wPtr, black, [rect_submit],5);
            Screen('DrawText',wPtr,'Conferma',(rect_submit(1) + rect_submit(3))/2-85,(rect_submit(2) + rect_submit(4))/2-20,black);
            
            %animation when scrolling over cards. If a card is clicked, "card" variable set [A,B,C,D]
            if x > rect_A(1) && x < rect_A(3) && y > rect_A(2) && y < rect_A(4)
                Screen('DrawTexture', wPtr, tex,[],rect_A2);
                Screen('DrawText',wPtr,'A',(rect_A(1) + rect_A(3))/2,(rect_A(2) + rect_A(4))/2,white);
                if buttons(1)
                    card = 'A';
                end
            elseif x > rect_B(1) && x < rect_B(3) && y > rect_B(2) && y < rect_B(4)
                Screen('DrawTexture', wPtr, tex,[],rect_B2);
                Screen('DrawText',wPtr,'B',(rect_B(1) + rect_B(3))/2,(rect_B(2) + rect_B(4))/2,white);
                if buttons(1)
                    card = 'B';
                end
            elseif x > rect_C(1) && x < rect_C(3) && y > rect_C(2) && y < rect_C(4)
                Screen('DrawTexture', wPtr, tex,[],rect_C2);
                Screen('DrawText',wPtr,'C',(rect_C(1) + rect_C(3))/2,(rect_C(2) + rect_C(4))/2,white);
                if buttons(1)
                    card = 'C';
                end
            elseif x > rect_D(1) && x < rect_D(3) && y > rect_D(2) && y < rect_D(4)
                Screen('DrawTexture', wPtr, tex,[],rect_D2);
                Screen('DrawText',wPtr,'D',(rect_D(1) + rect_D(3))/2,(rect_D(2) + rect_D(4))/2,white);
                if buttons(1)
                    card = 'D';
                end
            end
            
            %Change card graphic when "card" is set to a letter value, until another card is selected OR submit it pressed
            if card == 'A'
                Screen('DrawTexture', wPtr, tex,[],rect_A2);
                Screen('DrawText',wPtr,'A',(rect_A(1) + rect_A(3))/2,(rect_A(2) + rect_A(4))/2,white);
            elseif card == 'B'
                Screen('DrawTexture', wPtr, tex,[],rect_B2);
                Screen('DrawText',wPtr,'B',(rect_B(1) + rect_B(3))/2,(rect_B(2) + rect_B(4))/2,white);
            elseif card == 'C'
                Screen('DrawTexture', wPtr, tex,[],rect_C2);
                Screen('DrawText',wPtr,'C',(rect_C(1) + rect_C(3))/2,(rect_C(2) + rect_C(4))/2,white);
            elseif card == 'D'
                Screen('DrawTexture', wPtr, tex,[],rect_D2);
                Screen('DrawText',wPtr,'D',(rect_D(1) + rect_D(3))/2,(rect_D(2) + rect_D(4))/2,white);
            end
            
            %if submit button is scrolled over
            if x > rect_submit(1) && x < rect_submit(3) && y > rect_submit(2) && y < rect_submit(4)
                Screen('FillRect', wPtr, [155 155 155], rect_submit,5);
                Screen('DrawText',wPtr,'Conferma',(rect_submit(1) + rect_submit(3))/2-85,(rect_submit(2) + rect_submit(4))/2-20,white);
                %if button is pressed while submit is highlighted
                if buttons(1)
                    %update wins, loses and current total
                    switch card
                        case 'A'
                            win(i) = A_win;
                            lose(i) = A_loseRand(A_counter);
                            currTot = currTot + A_win - A_loseRand(A_counter);
                            allCurrTot(i+1) = currTot;
                            dat.IGT.choices(i) = card;
                            dat.IGT.wins = win;
                            dat.IGT.loses = lose;
                            dat.IGT.totals = allCurrTot;
                            save(['Data' fs dat.filename, 'dat']);
                            fprintf(fid,'selection for trial %d: A\n',i);
                        case 'B'
                            win(i) = B_win;
                            lose(i) = B_loseRand(B_counter);
                            currTot = currTot + B_win - B_loseRand(B_counter);
                            allCurrTot(i+1) = currTot;
                            dat.IGT.choices(i) = card;
                            dat.IGT.wins = win;
                            dat.IGT.loses = lose;
                            dat.IGT.totals = allCurrTot;
                            save(['Data' fs dat.filename, 'dat']);
                            fprintf(fid,'selection for trial %d: B\n',i);
                        case 'C'
                            win(i) = C_win;
                            lose(i) = C_loseRand(C_counter);
                            currTot = currTot + C_win - C_loseRand(C_counter);
                            allCurrTot(i+1) = currTot;
                            dat.IGT.choices(i) = card;
                            dat.IGT.wins = win;
                            dat.IGT.loses = lose;
                            dat.IGT.totals = allCurrTot;
                            save(['Data' fs dat.filename, 'dat']);
                            fprintf(fid,'selection for trial %d: C\n',i);
                        case 'D'
                            win(i) = D_win;
                            lose(i) = D_loseRand(D_counter);
                            currTot = currTot + D_win - D_loseRand(D_counter);
                            allCurrTot(i+1) = currTot;
                            dat.IGT.choices(i) = card;
                            dat.IGT.wins = win;
                            dat.IGT.loses = lose;
                            dat.IGTtotals = allCurrTot;
                            save(['Data' fs dat.filename, 'dat']);
                            fprintf(fid,'selection for trial %d: D\n',i);
                        otherwise
                            win(i) = NaN;
                            lose(i) = NaN;
                            allCurrTot(i+1) = allCurrTot(i);
                            dat.IGT.choices(i) = card;
                            dat.IGT.wins = win;
                            dat.IGT.loses = lose;
                            dat.IGT.totals = allCurrTot;
                            save(['Data' fs dat.filename, 'dat']);
                            fprintf(fid,'selection for trial %d: NA\n',i);
                            break;
                    end
                    
                    break;
                end
            end
            vbl = Screen('Flip',wPtr,vbl + (waitframes - 0.5) * ifi);
        end
        Screen(wPtr,'TextSize',35);
        if card == 'A'
            Screen('DrawTexture', wPtr, tex_fronte,[],rect_A2);
            Screen('FrameRect', wPtr, black, rect_A2,1.5);
            DrawFormattedText(wPtr,['Vinti: ' num2str(win(i)),' Euro'],rect_A(1)-5,((rect_A(2) + rect_A(4))/2)-40,green);
            DrawFormattedText(wPtr,['Persi: ' num2str(lose(i)),' Euro'],rect_A(1)-5,((rect_A(2) + rect_A(4))/2)+40,red);
            Screen('Flip',wPtr);
            WaitSecs(3);
        elseif card == 'B'
            Screen('DrawTexture', wPtr, tex_fronte,[],rect_B2);
            Screen('FrameRect', wPtr, black, rect_B2,1.5);
            DrawFormattedText(wPtr,['Vinti: ' num2str(win(i)),' Euro'],rect_B(1)-5,((rect_B(2) + rect_B(4))/2)-40,green);
            DrawFormattedText(wPtr,['Persi: ' num2str(lose(i)),' Euro'],rect_B(1)-5,((rect_B(2) + rect_B(4))/2)+40,red);
            Screen('Flip',wPtr);
            WaitSecs(3);
        elseif card == 'C'
            Screen('DrawTexture', wPtr, tex_fronte,[],rect_C2);
            Screen('FrameRect', wPtr, black, rect_C2,1.5);
            DrawFormattedText(wPtr,['Vinti: ' num2str(win(i)),' Euro'],rect_C(1)-5,((rect_C(2) + rect_C(4))/2)-40,green);
            DrawFormattedText(wPtr,['Persi: ' num2str(lose(i)),' Euro'],rect_C(1)-5,((rect_C(2) + rect_C(4))/2)+40,red);
            Screen('Flip',wPtr);
            WaitSecs(3);
        elseif card == 'D'
            Screen('DrawTexture', wPtr, tex_fronte,[],rect_D2);
            Screen('FrameRect', wPtr, black, rect_D2,1.5);
            DrawFormattedText(wPtr,['Vinti: ' num2str(win(i)),' Euro'],rect_D(1)-5,((rect_D(2) + rect_D(4))/2)-40,green);
            DrawFormattedText(wPtr,['Persi: ' num2str(lose(i)),' Euro'],rect_D(1)-5,((rect_D(2) + rect_D(4))/2)+40,red);
            Screen('Flip',wPtr);
            WaitSecs(3);
            
        end
        PsychPortAudio('Start', pahandle, repetitions,0,1); %starts sound immediatley
        PsychPortAudio('Stop', pahandle, 1, 1);
        number_cards = number_cards + 1;
        cards(i) = card;
        WaitSecs(.5);
    end
    dat.IGT.choices = cards;
    dat.IGT.wins = win;
    dat.IGT.loses = lose;
    dat.IGT.totals = allCurrTot;
    % allEnd = GetSecs;
    save(['Data' fs dat.filename, 'dat']);
    
    %Show a ending screen
    Screen('FillRect',wPtr,white,rect);
    DrawFormattedText(wPtr,'Lo studio è completo.','center','center',black);
    Screen('Flip',wPtr);
    KbWait([], 2);
    
    st = fclose(fid);
    ListenChar(1);
    Screen('CloseAll');
catch ERR
    Screen('CloseAll');
    rethrow( ERR );
end


% Perform some calculation and a report
Data = dat.IGT;

% Visualize Money-Time plot
Money = Data.totals;
Trials = 0 : ntrials;
figure
subplot(221)
plot(Trials,Money,'-o','linewidth',1.8,'Markersize',10,'MarkerFaceColor','r','color','k');
ylim([min(Money)-200 max(Money)+200])
hold on
plot([Trials(1) Trials(end)], [2000 2000],'linestyle','--','color','r','linewidth',1.5)
xlabel(' # Trial ')
xticks(Trials);
xticklabels(Trials);
ylabel(' Total Money [Euro]')
title(' Moneys-Trials on-going ')
subplot(222)
% Visualize deck-selection path
Cards = Data.choices;
Wins = Data.wins;
Loses = Data.loses;
Nets = Wins - Loses;
Good_trials = find(Nets > 0);
Bad_trials = find(Nets <= 0);
idx_A = strfind(Cards,'A');
idx_B = strfind(Cards,'B');
idx_C = strfind(Cards,'C');
idx_D = strfind(Cards,'D');
prop_A = numel(idx_A)/ntrials;
prop_B = numel(idx_B)/ntrials;
prop_C = numel(idx_C)/ntrials;
prop_D = numel(idx_D)/ntrials;
GS = numel(idx_C) + numel(idx_D) - numel(idx_A) - numel(idx_B);
Vect_Decks = zeros(1,ntrials);
Vect_Decks(idx_A) = 4;
Vect_Decks(idx_B) = 3;
Vect_Decks(idx_C) = 2;
Vect_Decks(idx_D) = 1;
plot(Vect_Decks,'-','linewidth',1.8,'color','k');
hold on
scatter(Good_trials,Vect_Decks(Good_trials),40,'o','MarkerFaceColor','r')
scatter(Bad_trials,Vect_Decks(Bad_trials),40,'o','MarkerFacecolor','k')
xlabel(' Current Trial ')
xticks(Trials);
xticklabels(Trials);
ylabel(' Selected Deck')
ylim([0 5])
yticks([1:4]);
yticklabels({'D','C','B','A'})
title(' Deck Selection Order ')
subplot(223)
% Visualize Global Score
bar(GS,'linewidth',1.5,'Edgecolor',black);
ylabel(' GS score ')
xticks(1);
xticklabels('GS')
% Visualize deck proportion choice
subplot(224)
bar([prop_A prop_B prop_C prop_D],'linewidth',1.5,'Edgecolor',black);
xticks(1:4)
xticklabels({'A','B','C','D'})
xlabel(' Deck ')
ylabel(' Proportion of Choice ')
title(' Deck Selection Proportion ')
cd(base_dir);

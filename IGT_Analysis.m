%% IGT analysis

clc
clear all
close all

% set data folder
data_folder = fullfile(pwd,'Data');

% add usefull toolboxes
MI_folder = fullfile(pwd,'MIToolbox-master');
addpath(genpath(MI_folder))
Gramm_folder = fullfile(pwd,'gramm-master');
addpath(genpath(Gramm_folder))

% if you hav some problems compile  CompileMIToolbox to generate -mex
% compiled files

n_subjects = 3; % number of subjects

% load data and perform already available analysis
% create suitable struct for analysis
IGT_struct = cell(1,n_subjects);
figure('renderer','painters')

for ID = 1 : n_subjects
    
    % filepath
    fp = fullfile(data_folder,['IGTDATA_',num2str(ID),'.mat']);
    
    % load data
    load(fp,'Data');
    
    % find # trials
    ntrials  = numel(Data.wins);
    
    % plot all available variables
    
    % Visualize Money-Time plot
    Trials = 0 : ntrials;
    
    s1 = subplot(221);
    hold on
    plot(s1,Trials,Data.totals,'-o','linewidth',1.8,'Markersize',2,'MarkerFaceColor','k');
    xlabel(' # Trial ')
    xticks(Trials(1:10:end));
    ylabel(' Total Money [Euro]')
    title(' Moneys-Trials on-going ')
    
    s2 = subplot(222);
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
    Vect_Decks(idx_A) = 1;
    Vect_Decks(idx_B) = 2;
    Vect_Decks(idx_C) = 3;
    Vect_Decks(idx_D) = 4;
    plot(s2,Vect_Decks,'-','linewidth',1,'linestyle','--');
    hold on
    xlabel(' Current Trial ')
    xticks(Trials(1:10:end));
    ylabel(' Selected Deck')
    ylim([0 5])
    yticks([1:4]);
    yticklabels({'A','B','C','D'})
    title(' Deck Selection Order ')
    subplot(2,2,[3,4])
    
    bar([prop_A prop_B prop_C prop_D],'linewidth',1.5,'Edgecolor','k');
    xticks(1:4)
    xticklabels({'A','B','C','D'})
    xlabel(' Deck ')
    ylabel(' Proportion of Choice ')
    title(' Deck Selection Proportion ')
    
    disp(['Build struct for subject n°' num2str(ID)])
  

    
    % find  no-choice trials
    no_choice_idx = find(isnan(Data.wins));
    valid_trials = ntrials - numel(no_choice_idx);
    
    IGT_struct{ID}.id = ID; % ID number of subject
    IGT_struct{ID}.trial = [1: valid_trials]'; % trials
    IGT_struct{ID}.win = Data.wins(not(isnan(Data.wins))); % wins
    IGT_struct{ID}.lose = - Data.loses(not(isnan(Data.loses))); % wins
    IGT_struct{ID}.money = Data.totals;
    IGT_struct{ID}.deck = Vect_Decks(Vect_Decks ~= 0);
    IGT_struct{ID}.prop = [prop_A prop_B prop_C prop_D];

end

plot(s1,[Trials(1) Trials(end)], [2000 2000],'linestyle','--','color','k','linewidth',1.5)
legend(s1,{'ID1','ID2','ID3','Start'})

subplot(2,2,[3,4])
prop_2plot = zeros(n_subjects,4);
for ii = 1 : n_subjects
    prop_2plot(ii,:) = IGT_struct{ii}.prop;
end
bar(prop_2plot')
ylabel(' Probability ')
xticklabels({'A','B','C','D'})
set(gca,'fontsize',15)
%%  compute behavioral measures
netscore_time = cell(1,n_subjects);
netscore_total = zeros(1,n_subjects);
WSLS = zeros(n_subjects,2);
H_total = zeros(1,n_subjects);
repeat_after_bigpun = zeros(1,n_subjects);
MI2choices_total = zeros(1,n_subjects);
directed_exploration3 = cell(1,n_subjects);
directed_exploration4 = cell(1,n_subjects);
chance_DE3 = zeros(1,n_subjects);
chance_DE4 = zeros(1,n_subjects);

for ID = 1 : n_subjects
    
    disp(['Compute behavioral measures for subject n°' num2str(ID)])
    ntrials = IGT_struct{ID}.trial(end);
    % compute net score
    netscore_time{ID} = cumsum(ismember(IGT_struct{ID}.deck, [3 4]))-cumsum(ismember(IGT_struct{ID}.deck, [1 2]));
    netscore_total(ID) = netscore_time{ID}(end);
    times_chosen = zeros(4,ntrials);
    avg_payoff = zeros(4,ntrials);
    
    for d=1:4
        times_chosen(d,:) = cumsum(IGT_struct{ID}.deck==d);
        dumpayoff = cumsum(double(IGT_struct{ID}.deck==d).*(IGT_struct{ID}.win-IGT_struct{ID}.lose));
        avg_payoff(d,:) = dumpayoff./times_chosen(d,:);
    end
    avg_payoff = [[NaN;NaN;NaN;NaN],avg_payoff(:,1:end-1)];
    times_chosen = [[0;0;0;0],times_chosen(:,1:end-1)];
    
    % compute win-stay lose-shift metrics
    stay = IGT_struct{ID}.deck(2:end)==IGT_struct{ID}.deck(1:end-1);
    prvloss = abs(IGT_struct{ID}.lose(1:end-1))>0;
    WSLS(ID,:) = [mean(stay(~prvloss)) mean(~stay(prvloss))];
    clear stay prvloss
    
    % evaluate repeat after bigpun
    bigpun_ind = find(IGT_struct{ID}.lose<=-1000);
    bigpun_number(ID) = numel(bigpun_ind);
    if ~isempty(bigpun_ind) && bigpun_ind(end)==100
        bigpun_ind(end)=[];
    end
    if ~isempty(bigpun_ind)
        repeat_after_bigpun(ID,1) = mean(double(IGT_struct{ID}.deck(bigpun_ind)==IGT_struct{ID}.deck(bigpun_ind+1)));
    else
        repeat_after_bigpun(ID,1) = NaN;
    end
    clear bigpun_ind
    
    % compute choice entropy and mutual information between successive
    % choices
    H_total(ID) = h(IGT_struct{ID}.deck');
    MI2choices_total(ID) = mi(IGT_struct{ID}.deck(1:end-1)',IGT_struct{ID}.deck(2:end)');
    
    % compute directed exploration indexes
    for t = 1: (ntrials - 2)
        directed_exploration3{ID}(t) = double(numel(unique(IGT_struct{ID}.deck(t:t+2)))==3);
        if t<(ntrials - 2)
            directed_exploration4{ID}(t) = double(numel(unique(IGT_struct{ID}.deck(t:t+3)))==4);
        end
    end

    % permute to obtain empirical chance levels on exploration indexes
    for r = 1:round(5000/length(IGT_struct{ID}))
        perm_deck = IGT_struct{ID}.deck(randperm(length(IGT_struct{ID}.deck)));
        for t = 1:length(perm_deck)-2
            perm_DE3(r,t) = double(numel(unique(perm_deck(t:t+2)))==3);
        end
        for t = 1:length(perm_deck)-3
            perm_DE4(r,t) = double(numel(unique(perm_deck(t:t+3)))==4);
        end
    end
    chance_DE3(ID) = mean2(perm_DE3);
    chance_DE4(ID) = mean2(perm_DE4);
    
end

%% plot outcomes

figure('renderer','painters')
subplot(1,3,[1 2])
hold on
for ID = 1: n_subjects
    plot(smooth(netscore_time{ID},3),'linewidth',2)
end
xlabel(' Trials ')
ylabel(' NET Score ')
title(' NET score in time')
legend({'ID1','ID2','ID3'})
set(gca,'fontsize',15)
subplot(1,3,3)
hold on
for ID = 1: n_subjects
    stem(ID,netscore_total(ID),'filled','markersize',15)
end
xlim([.5 3.5])
ylim([-6 10])
xticklabels({'ID1','ID2','ID3'})
ylabel(' NET Score ')
title(' Final NET Score ')
set(gca,'fontsize',15)

figure('renderer','painters')

subplot(2,2,1)
hold on
for ID = 1: n_subjects
    stem(ID,WSLS(ID,1),'filled','markersize',15)
end
xticks(1:n_subjects)
xticklabels({'ID1','ID2','ID3'})
xlim([.5 3.5])
ylabel(' frequency ')
title(' Win Stay ')
set(gca,'fontsize',15)

subplot(2,2,2)
hold on
for ID = 1: n_subjects
    stem(ID,WSLS(ID,2),'filled','markersize',15)
end
xticks(1:n_subjects)
xticklabels({'ID1','ID2','ID3'})
xlim([.5 3.5])
ylabel(' frequency ')
title(' Lose Shift ')
set(gca,'fontsize',15)

subplot(2,2,3)
hold on
for ID = 1: n_subjects
    stem(ID,H_total(ID),'filled','markersize',15)
end
xticks(1:n_subjects)
xticklabels({'ID1','ID2','ID3'})
xlim([.5 3.5])
ylabel(' Entropy [bits] ')
title(' Entropy ')
set(gca,'fontsize',15)

subplot(2,2,4)
hold on
for ID = 1: n_subjects
    stem(ID,MI2choices_total(ID),'filled','markersize',15)
end
xticks(1:n_subjects)
xticklabels({'ID1','ID2','ID3'})
xlim([.5 3.5])
ylabel(' MI(i,i+1) [bits] ')
title(' Mutual information ')
set(gca,'fontsize',15)

figure('renderer','painters')
subplot(2,3,[1 2])
hold on
for ID = 1: n_subjects
    plot(smooth(directed_exploration3{ID},3),'linewidth',2)
end
plot([1 100],[0.33 0.33]','--','color','k','linewidth',1.8)
xlabel(' Trials ')
ylabel(' 3-Pattern Frequency ')
title(' 3-Sequential exploration in time')
set(gca,'fontsize',15)
subplot(2,3,3)
hold on
for ID = 1: n_subjects
    stem(ID,mean(directed_exploration3{ID}),'filled','markersize',15)
end
plot([0.5 3.5],[0.33 0.33]','--','color','k','linewidth',1.8)
xlim([.5 3.5])
ylim([0 .75])
xticklabels({'ID1','ID2','ID3'})
ylabel(' 3-Pattern Frequency ')
title(' Final SE3 ')
set(gca,'fontsize',15)

subplot(2,3,[4 5])
hold on
for ID = 1: n_subjects
    plot(smooth(directed_exploration4{ID},3),'linewidth',2)
end
plot([1 100],[0.09 0.09]','--','color','k','linewidth',1.8)
xlabel(' Trials ')
ylabel(' 4-Pattern Frequency ')
title(' 4-Sequential exploration in time')
set(gca,'fontsize',15)
subplot(2,3,6)
hold on
for ID = 1: n_subjects
    stem(ID,mean(directed_exploration4{ID}),'filled','markersize',15)
end
plot([0.5 3.5],[0.09 0.09]','--','color','k','linewidth',1.8)

xlim([.5 3.5])
ylim([0 .75])
xticklabels({'ID1','ID2','ID3'})
ylabel(' 4-Pattern Frequency ')
title(' Final SE4 ')
set(gca,'fontsize',15)
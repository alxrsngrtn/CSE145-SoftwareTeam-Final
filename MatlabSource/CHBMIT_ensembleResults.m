function [ results ] =      ...
    CHBMIT_ensembleResults( ...
    params, data, labels, lv_test)

assert(nargin == 4);

flags_augmentResults = params.flags.augmentResults;

numModules     = params.numModules;
samplingFreq   = params.samplingFreq;
windowSize     = params.windowSize_sec*samplingFreq;
windowSlide    = params.windowSlide_sec*samplingFreq;
testSegments   = params.testSegments;
seizures       = params.seizures;


secsPerLabel = params.windowSlide_sec;

fprintf('\n');
fprintf('Results...\n');
fprintf('\n');

numSegs = testSegments(end)-testSegments(1)+1;
results = [];

offset = 1;

for seg = testSegments
    
    count(seg).tot.S  = 0;
    count(seg).tot.N  = 0;

    count(seg).good.S = 0;
    count(seg).good.N = 0;
    
    fprintf('Segment %d\n', seg);
    fprintf('\n');
    
    seizureIndex = find(seizures(:,1) == seg);
    numSeizures  = size(seizureIndex,1);
    
    segmentLength     = size(data(seg).record,2);
    segmentLength_sec = segmentLength/samplingFreq;
    
    numLabelsInSeg = segmentLength/windowSlide - windowSize/windowSlide +1;
    
    if numSeizures >= 1
        
        seizurePresent = 1;
        fprintf('  Seizure detected at...\n');
        
        for i = (1:numSeizures)
            
            seizureStart = seizures(seizureIndex(i),2);
            seizureEnd   = seizures(seizureIndex(i),3);
            fprintf('    [should be %d to %d seconds]\n', ...
                seizureStart, seizureEnd);
            
        end
        
    else
        
        seizurePresent = 0;
        fprintf('  Seizure detected at...\n')
        fprintf('    [should be none]\n')
        
    end
    
    fprintf('\n');
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    theseLabels = labels(offset:offset+numLabelsInSeg-1);
    
    detectedSeizures = [];
    
    for l = (1:numLabelsInSeg)
        
        count(seg).tot.S = count(seg).tot.S + theseLabels(l);
        count(seg).tot.N = count(seg).tot.N + ~theseLabels(l);
        
        time_sec = 1+(l-1)*secsPerLabel;
            
        if theseLabels(l)
            detectedSeizures = ...
                [detectedSeizures time_sec];
        end
        
        if seizurePresent
            
            seizureStart = ...
                seizures( find(seizures(:,1) == seg), 2);
            
            seizureEnd   = ...
                seizures( find(seizures(:,1) == seg), 3);
            
            for seiz = (1:numSeizures)
                
                if (time_sec >= seizureStart(seiz)) && ...
                        (time_sec <= seizureEnd(seiz))
                    
                    if theseLabels(l)
                        count(seg).good.S = count(seg).good.S+1;
                    end
                    
                    break;
                    
                elseif ~theseLabels(l)
                    count(seg).good.N = count(seg).good.N+1;
                end
                
            end
            
        elseif ~theseLabels(l)
            count(seg).good.N = count(seg).good.N+1;
        end
           
    end
    
    
    seiz = 1;
    
    while seiz <= length(detectedSeizures)-1
        
        thisRow  = [seg detectedSeizures(seiz)];
        
        while detectedSeizures(seiz+1) == ...
                detectedSeizures(seiz) + secsPerLabel
        
            seiz = seiz+1;
            
            if seiz == length(detectedSeizures)
                break;
            end
           
        end
        
        thisRow = [thisRow  detectedSeizures(seiz) + secsPerLabel];
        results = [results; thisRow];
        
        seiz = seiz + 1;
        
    end
    
    fprintf('\n');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    offset = offset + numLabelsInSeg;
    
    fprintf('   %d/%d -> %.1f%% of SEIZURE labels are correct.\n',  ...
    	count(seg).good.S, count(seg).tot.S,                        ...
    	(100*count(seg).good.S)/count(seg).tot.S);
        

    fprintf('\n');
    fprintf('   %d/%d -> %.1f%% of NON-SEIZURE labels are correct.\n', ...
        count(seg).good.N, count(seg).tot.N,                           ...
     	(100*count(seg).good.N)/count(seg).tot.N);
    
    fprintf('\n');
    fprintf('   %d/%d -> %.1f%% of ALL labels are correct.\n', ...
        count(seg).good.N+count(seg).good.S,                   ...
        count(seg).tot.N+count(seg).tot.S,                     ...
     	(100*(count(seg).good.N+count(seg).good.S))/           ...
        (count(seg).tot.N+count(seg).tot.S));
    
    fprintf('\n');
end

results_preAugmentation = results

if flags_augmentResults
    
    fprintf('\n');
    fprintf('Augmenting Results...\n');
    
    seiz = 1;
    
    while seiz <= size(results,1)-1
        
        this_startTime = results(seiz, 2);
        this_endTime   = results(seiz, 3);
        
        next_startTime = results(seiz+1, 2);
        next_endTime   = results(seiz+1, 3);
        
        if next_startTime <= this_endTime + 5*secsPerLabel
            
        	results(seiz,   3) = next_endTime;
            results(seiz+1, :) = [];
            
            seiz = seiz+1;
            
        elseif this_endTime <= this_startTime + secsPerLabel*2
            
            results(seiz,:) = [];
            
        else
            seiz = seiz+1;
        end
        
    end
    
    fprintf('Done.\n');
    results_posAugmentation = results
    
end


fprintf('\n');
fprintf('\n');
fprintf('Process Complete.\n');
fprintf('\n');

end


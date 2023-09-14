function [x, indexes] = smoothOut(x)
    indexes = [];
    for i = length(x)-1:-1:1
        if(x(i) < x(i+1))
            x(i) = [];
            indexes = [i indexes];
        end
    end
end
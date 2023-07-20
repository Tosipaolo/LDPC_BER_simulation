
% 
% for i = complex([1:100],[95:-1:-4])
%     i
%     validateattributes(i, {'double','single'}, {'finite','2d'}, mfilename, 'Y');
% end

NoisySignal(~isfinite(NoisySignal))
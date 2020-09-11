function h1=plplot(xin, xmin_in, alpha_in, xout, xmin_out, alpha_out, plot_title, which_experiment,  pos)
% PLPLOT visualizes a power-law distributional model with empirical data.
%    Source: http://www.santafe.edu/~aaronc/powerlaws/
% 
%    PLPLOT(x, xmin, alpha) plots (on log axes) the data contained in x 
%    and a power-law distribution of the form p(x) ~ x^-alpha for 
%    x >= xmin. For additional customization, PLPLOT returns a pair of 
%    handles, one to the empirical and one to the fitted data series. By 
%    default, the empirical data is plotted as 'bo' and the fitted form is
%    plotted as 'k--'. PLPLOT automatically detects whether x is composed 
%    of real or integer values, and applies the appropriate plotting 
%    method. For discrete data, if min(x) > 50, PLFIT uses the continuous 
%    approximation, which is a reliable in this regime.
%
%    Example:
%       xmin  = 5;
%       alpha = 2.5;
%       x = xmin.*(1-rand(10000,1)).^(-1/(alpha-1));
%       h = plplot(x,xmin,alpha);
%
%    For more information, try 'type plplot'
%
%    See also PLFIT, PLVAR, PLPVA

% Version 1.0   (2008 February)
% Copyright (C) 2008-2011 Aaron Clauset (Santa Fe Institute)
% Distributed under GPL 2.0
% http://www.gnu.org/copyleft/gpl.html
% 
% Modified by Adriano J. Holanda (University of São Paulo)
% 2018
% LICENSE: GPL 2.0
% http://www.gnu.org/copyleft/gpl.html

% change plot layout accordingly
Dim = [2, 2];
if strcmp(which_experiment, 'kernel')
    Dim = [4, 3];
else
    Dim = [3, 3]
end

% reshape input vector
xin = reshape(xin,numel(xin),1);
xout = reshape(xout,numel(xout),1);
% initialize storage for output handles
h1 = zeros(2,1);

% there will be on continuous method

x = xin
xmin = xmin_in
alpha = alpha_in
n = length(x);
q = unique(x);
c = hist(x,q)'./n;
c = [[q; q(end)+1] 1-[0; cumsum(c)]]; c(c(:,2)<10^-10,:) = [];
cf = ((xmin:q(end))'.^-alpha)./(zeta(alpha) - sum((1:xmin-1).^-alpha));
cf = [(xmin:q(end)+1)' 1-[0; cumsum(cf)]];
cf(:,2) = cf(:,2) .* c(c(:,1)==xmin,2);

subplot(Dim(1) , Dim(2), pos);
h1(1) = loglog(c(:,1),c(:,2),'bo','MarkerSize',8,'MarkerFaceColor',[1 1 1]); hold on;
h1(2) = loglog(cf(:,1),cf(:,2),'k--','LineWidth',2);

x = xout
xmin = xmin_out
alpha = alpha_out
n = length(x);
q = unique(x);
c = hist(x,q)'./n;
c = [[q; q(end)+1] 1-[0; cumsum(c)]]; c(c(:,2)<10^-10,:) = [];
cf = ((xmin:q(end))'.^-alpha)./(zeta(alpha) - sum((1:xmin-1).^-alpha));
cf = [(xmin:q(end)+1)' 1-[0; cumsum(cf)]];
cf(:,2) = cf(:,2) .* c(c(:,1)==xmin,2);

h2(1) = loglog(c(:,1),c(:,2),'rx','MarkerSize',8,'MarkerFaceColor',[1 1 1]); hold on;
h2(2) = loglog(cf(:,1),cf(:,2),'k-.','LineWidth',2);

% TICKS
x = [xin; xout];
xr  = [10.^floor(log10(min(nonzeros(x)))) 10.^ceil(log10(max(x)))];
xrt = (round(log10(xr(1))):2:round(log10(xr(2))));
if length(xrt)<4, xrt = (round(log10(xr(1))):1:round(log10(xr(2)))); end;
yr  = [10.^floor(log10(1/n)) 1];
yrt = (round(log10(yr(1))):2:round(log10(yr(2))));
if length(yrt)<4, yrt = (round(log10(yr(1))):1:round(log10(yr(2)))); end;
set(gca,'XLim',xr,'XTick',10.^xrt);
set(gca,'YLim',yr,'YTick',10.^yrt,'FontSize',16);

if pos == 1 || pos == 4 || pos == 7 || pos == 10
    ylabel('Pr(X \geq x)','FontSize',16);
end

if pos > 9
    xlabel('x','FontSize',16);
end

if pos == 1
    lgd = legend([h1(1), h2(1)],{'indegree', 'outdegree'})
    lgd.FontSize = 12
end

tit = title(plot_title)
tit.FontSize = 14     

return;


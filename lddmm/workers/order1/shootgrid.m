%
%  segframe, Copyright (C) 2009-2012, Stefan Sommer (sommer@diku.dk)
%  https://github.com/nefan/segframe.git
% 
%  This file is part of segframe.
% 
%  segframe is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
% 
%  segframe is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
% 
%  You should have received a copy of the GNU General Public License
%  along with segframe.  If not, see <http://www.gnu.org/licenses/>.
%  

function [grid1 gridt] = shootgrid(grid0,rhott,lddmmoptions,varargin)

dim = lddmmoptions.dim;
cdim = lddmmoptions.cdim;
L = lddmmoptions.L;
R = lddmmoptions.R;
CSP = lddmmoptions.CSP;
scales = lddmmoptions.scales;
scaleweight = lddmmoptions.scaleweight;

[Ks D1Ks D2Ks] = gaussianKernels();

Ngrid = numel(grid0{1});

backwards = false;
if size(varargin,2) > 0
    backwards = varargin{1};
end
tend = 1;
if size(varargin,2) > 1
    tend = varargin{2};
end
% % for movies
% selectscale = -1;
% if size(varargin,2) > 1
%     selectscale = varargin{2};
% end

function dgrid = Gc(tt,gridt) % wrapper for C version
    t = intTime(tt,backwards,lddmmoptions);  
    rhot = deval(rhott,t);
    
%     if selectscale > 0
%         rhot = reshape(rhot,CSP,L);
% 
%         rhots = zeros(size(rhot));
%         rhots(1:dim,:) = rhot(1:dim,:); % points
%         rhots(dim+(selectscale-1)*dim+1:dim+(selectscale-1)*dim+dim,:) = rhot(dim+(selectscale-1)*dim+1:dim+(selectscale-1)*dim+dim,:);
%         rhot = reshape(rhots,CSP*L,1);
%     end
       
    dgrid = fastPointTransportOrder0(t,gridt,rhot,L,R,cdim,scales.^2,scaleweight.^2); 
    dgrid = intResult(dgrid,backwards,lddmmoptions);
    
    % debug
    if getOption(lddmmoptions,'testC')
        assert(selectscale == -1); % not implemented for G
        dgrid2 = G(tt,gridt);
        assert(norm(dgrid-dgrid2) < 10e-12);
    end
end

function dgrid = G(tt,grid) % slooow version
    t = intTime(tt,backwards,lddmmoptions);  
    grid = reshape(grid,3,Ngrid);
    
    dgrid = zeros(size(grid));
    
    rhot = deval(rhott,t);
    if dim ~= cdim
        rhot = rho3dTo2dOrder0(rhot,lddmmoptions);
    end
    rhot = reshape(rhot,CSP,L);
    
    for i = 1:Ngrid % grid point
        for l = 1:L % particle
            for s = 1:R % scale
                dgrid(1:dim,i) = dgrid(1:dim,i)+Ks(grid(1:dim,i),rhot(1:dim,l),scales(s),scaleweight(s))*rhot(dim*(s-1)+(1+dim:2*dim),l);
            end
        end
    end
    
    dgrid = intResult(dgrid,backwards,lddmmoptions);
    
    dgrid = reshape(dgrid,3*Ngrid,1);    
end

siz = size(grid0{1});
g0 = reshape([reshape(grid0{1},1,Ngrid); reshape(grid0{2},1,Ngrid); reshape(grid0{3},1,Ngrid)],3*Ngrid,1);
gridt = ode45(@Gc,[0 tend],g0);
g1 = reshape(deval(gridt,tend),3,Ngrid);
grid1 = cell(1);
grid1{1} = reshape(g1(1,:),siz);
grid1{2} = reshape(g1(2,:),siz);
grid1{3} = reshape(g1(3,:),siz);

end
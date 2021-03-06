



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!compute terms of the momentum equations in ROMS
!!
!! Note that MHdiff is the difference between upstream and 4th order centered advection (and not the sponge dissipation)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

      subroutine get_uv_evolution  (Lm,Mm,N,u,v,T,S, z_r,z_w
     &  ,pm,pn,f,dt
     &  ,rdrg, rho0, W, Akv, sustr, svstr
     &  ,MXadv, MYadv, MVadv, MHdiff,  MVmix, MCor, MPrsgrd)


      implicit none

      integer Lm,Mm,N, imin,imax,jmin,jmax, i,j,k,
     &      istr,iend,jstr,jend,dt,istrU,jstrV,
     &      itrc

        !INPUT
      real*8 u(1:Lm+1,0:Mm+1,N),  v(0:Lm+1,1:Mm+1,N)
     &      ,z_r(0:Lm+1,0:Mm+1,N),  z_w(0:Lm+1,0:Mm+1,0:N)
     &      ,pm(0:Lm+1,0:Mm+1), pn(0:Lm+1,0:Mm+1)
     &      ,f(0:Lm+1,0:Mm+1)
     &      ,W(0:Lm+1,0:Mm+1,0:N)
     &      ,Akv(0:Lm+1,0:Mm+1,0:N)
     &      ,sustr(1:Lm+1,0:Mm+1), svstr(0:Lm+1,1:Mm+1)

      ! OUTPUTS
      real*8 MXadv(1:Lm,1:Mm,N,2)
     &      ,MYadv(1:Lm,1:Mm,N,2)
     &      ,MVadv(1:Lm,1:Mm,N,2)
     &      ,MHdiff(1:Lm,1:Mm,N,2)
     &      ,MVmix(1:Lm,1:Mm,N,2)
     &      ,MCor(1:Lm,1:Mm,N,2)
     &      ,MPrsgrd(1:Lm,1:Mm,N,2)


      real*8 rdrg, Zob

      real*8 FlxU(1:Lm+1,0:Mm+1,N),  FlxV(0:Lm+1,1:Mm+1,N),
     &      Hz(0:Lm+1,0:Mm+1,N), gamma,
     &      dn_u(0:Lm+1,0:Mm+1), dm_v(0:Lm+1,0:Mm+1),
     &      dm_u(0:Lm+1,0:Mm+1), dn_v(0:Lm+1,0:Mm+1),
     &      fomn(0:Lm+1,0:Mm+1),
     &      var1, var2,var3, var4, cff, cff1, cff2

      real*8 ru(1:Lm+1,0:Mm+1,N),  rv(0:Lm+1,1:Mm+1,N)

      real*8 wrk1(0:Lm+1,0:Mm+1), wrk2(0:Lm+1,0:Mm+1),
     &      UFx(0:Lm+1,0:Mm+1), UFe(0:Lm+1,0:Mm+1),
     &      VFx(0:Lm+1,0:Mm+1), VFe(0:Lm+1,0:Mm+1),
     &      UFx_mix(0:Lm+1,0:Mm+1), UFe_mix(0:Lm+1,0:Mm+1),
     &      VFx_mix(0:Lm+1,0:Mm+1), VFe_mix(0:Lm+1,0:Mm+1),
     &      dmde(1:Lm,1:Mm), dndx(1:Lm,1:Mm)

      real*8 FC(0:Lm+1,0:N), DC(0:Lm+1,0:N)
     &      ,CF(0:Lm+1,0:N)


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

      real*8 T(0:Lm+1,0:Mm+1,N),  S(0:Lm+1,0:Mm+1,N),
     &      rho1(0:Lm+1,0:Mm+1,N), qp1(0:Lm+1,0:Mm+1,N),
     &      Tt,Ts,sqrtTs, rho0,  K0, dr00,
     &      cfr, HalfGRho, GRho

      real*8 P(0:Lm+1,0:Mm+1,N),
     &      rho(0:Lm+1,0:Mm+1,N), dpth,
     &      dR(0:Lm+1,N), dZ(0:Lm+1,N),
     &      dZx(0:Lm+1,0:Mm+1),
     &      rx(0:Lm+2,0:Mm+2), dRx(0:Lm+1,0:Mm+1)

      real*8, parameter :: OneFifth=0.2, OneTwelfth=1./12., epsil=0.

      real*8, parameter :: r00=999.842594,   r01=6.793952E-2,
     &          r02=-9.095290E-3, r03=1.001685E-4,  r04=-1.120083E-6,
     &                                              r05=6.536332E-9,
     &          r10=0.824493,     r11=-4.08990E-3,  r12=7.64380E-5,
     &                            r13=-8.24670E-7,  r14=5.38750E-9,
     &          rS0=-5.72466E-3,  rS1=1.02270E-4,   rS2=-1.65460E-6,
     &          r20=4.8314E-4,
     &          K00=19092.56,     K01=209.8925,     K02=-3.041638,
     &                            K03=-1.852732e-3, K04=-1.361629e-5,
     &          K10=104.4077,     K11=-6.500517,    K12=0.1553190,
     &                                              K13=2.326469e-4,
     &          KS0=-5.587545,    KS1=+0.7390729,   KS2=-1.909078e-2,
     &          qp2=0.0000172

#  ifdef DUKO_2001
      real rho1_0, K0_Duk
#  endif


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



# include "scalars.h"

      parameter (gamma=0.25)  


# define UPSTREAM
# define NO_SLIP_BOTTOM



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


Cf2py intent(in) Lm,Mm,N,u,v,T,S,z_r,z_w,pm,pn,f,dt,rdrg,rho0,W,Akv,sustr, svstr
Cf2py intent(out) MXadv, MYadv, MVadv, MHdiff, Mcor, MVmix, MPrsgrd


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


        imin=0
        imax=Lm+1
        jmin=0
        jmax=Mm+1

        istr=1
        iend=Lm
        jstr=1
        jend=Mm

        istrU=2
        jstrV=2

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


      do j=jmin,jmax
        do i=imin,imax
          do k=1,N,+1
           Hz(i,j,k) = z_w(i,j,k) - z_w(i,j,k-1)
          enddo
           fomn(i,j)=f(i,j)/(pm(i,j)*pn(i,j))
        enddo
      enddo


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

      do j=jmin,jmax
        do i=imin,imax
          do k=0,N,+1
              W(i,j,k)=W(i,j,k)/(pm(i,j)*pn(i,j))
            enddo
          enddo
        enddo

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        do j=jmin,jmax
          do i=imin+1,imax
            dm_u(i,j) = 2./(pm(i,j)+pm(i-1,j))
          enddo
        enddo

        do j=jmin+1,jmax
          do i=imin,imax
            dn_v(i,j) = 2./(pn(i,j)+pn(i,j-1))
          enddo
        enddo



      do j=jmin,jmax
        do i=imin+1,imax
            dn_u(i,j) = 2./(pn(i,j)+pn(i-1,j))
            do k=1,N,+1
              FlxU(i,j,k) = 0.5*(Hz(i,j,k)+Hz(i-1,j,k))*dn_u(i,j)
     &      * u(i,j,k) 
            enddo
          enddo
      enddo



      do j=jmin+1,jmax
        do i=imin,imax
            dm_v(i,j) = 2./(pm(i,j)+pm(i,j-1))
            do k=1,N,+1
              FlxV(i,j,k) = 0.5*(Hz(i,j,k)+Hz(i,j-1,k))*dm_v(i,j)
     &      * v(i,j,k) 
            enddo
          enddo
      enddo


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# include "compute_prsgrd.h"

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



!

      do j=jmin+1,jmax-1
        do i=imin+1,imax-1
            dmde(i,j) = 0.5/pm(i,j+1)-0.5/pm(i,j-1)
            dndx(i,j) = 0.5/pn(i+1,j)-0.5/pn(i-1,j)
         enddo
      enddo

      do k=1,N
!
# if defined UV_COR || (defined CURVGRID && defined UV_ADV)

!
! Add in Coriolis and curvilinear transformation terms, if any.
!
        do j=jstr,jend
          do i=istr,iend
            cff=0.5*Hz(i,j,k)*(
#  ifdef UV_COR
     &              fomn(i,j)
#  endif
#  if (defined CURVGRID && defined UV_ADV)
     &             +0.5*( (v(i,j,k)+v(i,j+1,k))*dndx(i,j)
     &                   -(u(i,j,k)+u(i+1,j,k))*dmde(i,j))
#  endif
     &                                                             )
            UFx(i,j)=cff*(v(i,j,k)+v(i,j+1,k))
            VFe(i,j)=cff*(u(i,j,k)+u(i+1,j,k))
          enddo
        enddo
        do j=jstr,jend
          do i=istrU,iend
            ru(i,j,k)=ru(i,j,k)+0.5*(UFx(i,j)+UFx(i-1,j))
             MCor(i,j,k,1) = 0.5*(UFx(i,j)+UFx(i-1,j))
          enddo
        enddo
        do j=jstrV,jend
          do i=istr,iend
            rv(i,j,k)=rv(i,j,k)-0.5*(VFe(i,j)+VFe(i,j-1))
            MCor(i,j,k,2) = -0.5*(VFe(i,j)+VFe(i,j-1))
          enddo
        enddo
# endif











# ifdef UV_ADV
!
! Add in horizontal advection of momentum: Compute diagonal [UFx,VFe]
! and off-diagonal [UFe,VFx] components of tensor of momentum flux
! due to horizontal advection; after that add divergence of these
! terms to r.h.s.
!
#  define uxx wrk1
#  define Huxx wrk2

        do j=jstr,jend
          do i=imin+2,imax-1
            uxx(i,j)=u(i-1,j,k)-2.*u(i,j,k)
     &                                +u(i+1,j,k)
            Huxx(i,j)=FlxU(i-1,j,k)-2.*FlxU(i,j,k)
     &                                  +FlxU(i+1,j,k)
          enddo
        enddo



        do j=jmin,jmax
         do i=imin+2,imax-2
            cff=FlxU(i,j,k)+FlxU(i+1,j,k)-0.125*( Huxx(i  ,j)
     &                                           +Huxx(i+1,j))
            UFx(i,j)=0.25*( cff*(u(i,j,k)+u(i+1,j,k))
     &                          -gamma*( max(cff,0.)*uxx(i  ,j)
     &                                  +min(cff,0.)*uxx(i+1,j)
     &                                                      ))

            UFx_mix(i,j)=UFx(i,j)-0.25*( u(i,j,k)+u(i+1,j,k)
     &                         -0.125*(uxx(i,j)+uxx(i+1,j))
     &                  )*( FlxU(i,j,k)+FlxU(i+1,j,k)
     &                      -0.125*(Huxx(i,j)+Huxx(i+1,j)))

          enddo
        enddo
#  undef Huxx
#  undef uxx

#  define vee wrk1
#  define Hvee wrk2

        do j=jmin+2,jmax-1
          do i=imin,imax
            vee(i,j)=v(i,j-1,k)-2.*v(i,j,k)+v(i,j+1,k)
            Hvee(i,j)=FlxV(i,j-1,k)-2.*FlxV(i,j,k)+FlxV(i,j+1,k)
          enddo
        enddo


        do j=jmin+2,jmax-2
         do i=imin,imax
            cff=FlxV(i,j,k)+FlxV(i,j+1,k)-0.125*( Hvee(i,j  )
     &                                           +Hvee(i,j+1))
            VFe(i,j)=0.25*( cff*(v(i,j,k)+v(i,j+1,k))
     &                          -gamma*( max(cff,0.)*vee(i,j  )
     &                                  +min(cff,0.)*vee(i,j+1)
     &                                                      )) 

            VFe_mix(i,j)=VFe(i,j)-0.25*( v(i,j,k)+v(i,j+1,k)
     &                        -0.125*(vee(i,j)+vee(i,j+1))
     &                  )*( FlxV(i,j,k)+FlxV(i,j+1,k)
     &                      -0.125*(Hvee(i,j)+Hvee(i,j+1)))

          enddo
        enddo
#  undef Hvee
#  undef vee

#  define uee wrk1
#  define Hvxx wrk2

        do j=jmin+1,jmax-1
          do i=imin+1,imax
            uee(i,j)=u(i,j-1,k)-2.*u(i,j,k)
     &                                 +u(i,j+1,k)
          enddo
        enddo

        do j=jmin+1,jmax
          do i=imin+1,imax-1
           Hvxx(i,j)=FlxV(i-1,j,k)-2.*FlxV(i,j,k)+FlxV(i+1,j,k)
          enddo
        enddo

        do j=jmin+2,jmax-1
         do i=imin+2,imax-1

            cff=FlxV(i,j,k)+FlxV(i-1,j,k)-0.125*( Hvxx(i  ,j)
     &                                           +Hvxx(i-1,j))
            UFe(i,j)=0.25*( cff*(u(i,j,k)+u(i,j-1,k))
     &                          -gamma*( max(cff,0.)*uee(i,j-1)
     &                                  +min(cff,0.)*uee(i,j  )
     &                                                      ))

            UFe_mix(i,j)=UFe(i,j)-0.25*( u(i,j,k)+u(i,j-1,k)
     &                        -0.125*(uee(i,j)+uee(i,j-1))
     &                  )*( FlxV(i,j,k)+FlxV(i-1,j,k)
     &                     -0.125*(Hvxx(i,j)+Hvxx(i-1,j)))

          enddo
        enddo
#  undef Hvxx
#  undef uee

#  define vxx wrk1
#  define Huee wrk2

        do j=jmin+1,jmax
         do i=imin+1,imax-1
            vxx(i,j)=v(i-1,j,k)-2.*v(i,j,k)
     &                                 +v(i+1,j,k)
          enddo
        enddo

        do j=jmin+1,jmax-1
         do i=imin+1,imax
           Huee(i,j)=FlxU(i,j-1,k)-2.*FlxU(i,j,k)+FlxU(i,j+1,k)
          enddo
        enddo

        do j=jmin+2,jmax-1
         do i=imin+2,imax-1

            cff=FlxU(i,j,k)+FlxU(i,j-1,k)-0.125*( Huee(i,j  )
     &                                           +Huee(i,j-1))
            VFx(i,j)=0.25*( cff*(v(i,j,k)+v(i-1,j,k))
     &                          -gamma*( max(cff,0.)*vxx(i-1,j)
     &                                  +min(cff,0.)*vxx(i  ,j)
     &                                                      ))

            VFx_mix(i,j)=VFx(i,j)-0.25*( v(i,j,k)+v(i-1,j,k)
     &                        -0.125*(vxx(i,j)+vxx(i-1,j))
     &                  )*( FlxU(i,j,k)+FlxU(i,j-1,k)
     &                     -0.125*(Huee(i,j)+Huee(i,j-1)))

          enddo
        enddo
#  undef Huee
#  undef vxx
        do j=jmin+2,jmax-2
         do i=imin+2,imax-2
            ru(i,j,k)=ru(i,j,k)-UFx(i,j  )+UFx(i-1,j)
     &                         -UFe(i,j+1)+UFe(i  ,j)



              MXadv(i,j,k,1) = -UFx(i,j)+UFx(i-1,j)
              MYadv(i,j,k,1) = -UFe(i,j+1)+UFe(i,j)

              MHdiff(i,j,k,1) = -UFx_mix(i,j)+UFx_mix(i-1,j)
     &                         -UFe_mix(i,j+1)+UFe_mix(i,j)


          enddo
        enddo

        do j=jmin+2,jmax-2
         do i=imin+2,imax-2
            rv(i,j,k)=rv(i,j,k)-VFx(i+1,j)+VFx(i,j  )
     &                         -VFe(i  ,j)+VFe(i,j-1)

              MXadv(i,j,k,2) = -VFx(i+1,j)+VFx(i,j)
              MYadv(i,j,k,2) = -VFe(i,j)+VFe(i,j-1)

              MHdiff(i,j,k,2) = -VFx_mix(i+1,j)+VFx_mix(i,j)
     &                         -VFe_mix(i,j)+VFe_mix(i,j-1)

          enddo
        enddo
# endif /* UV_ADV */
      enddo
































!
! Dynamic bottom drag coefficient
!
# define rd VFe
        Zob=0.01
       do j=jmin+1,jmax-1
         do i=imin+1,imax-1
# ifdef LINEAR_DRAG_ONLY
            rd(i,j)=rdrg
# else
            cff=sqrt( 0.333333333333*(
     &              u(i,j,1)**2 +u(i+1,j,1)**2
     &                    +u(i,j,1)*u(i+1,j,1)
     &              +v(i,j,1)**2+v(i,j+1,1)**2
     &                    +v(i,j,1)*v(i,j+1,1)
     &                                               ))

c**         rd(i,j)=rdrg + rdrg2*cff

            rd(i,j)=rdrg + cff*(vonKar/log(Hz(i,j,1)/Zob))**2


# endif
          enddo
        enddo

       do j=jmin+1,jmax
            rd(imax ,j)=rd(imax-1 ,j)
            rd(imin ,j)=rd(imin+1 ,j)
        enddo

       do i=imin+1,imax
            rd(i ,jmax)=rd(i ,jmax-1)
            rd(i ,jmin)=rd(i ,jmin+1)
        enddo














      do j=jstr,jend
# ifdef UV_ADV
!
! Compute and add in vertical advection terms:
!
# define SPLINES
# define NEUMANN
 
#  ifdef SPLINES
        do i=istrU,iend
          DC(i,1)=0.5625*(Hz(i  ,j,1)+Hz(i-1,j,1))
     &           -0.0625*(Hz(i+1,j,1)+Hz(i-2,j,1))
#  if defined NEUMANN
          FC(i,0)=1.5*u(i,j,1)
          CF(i,1)=0.5
#  elif defined LINEAR_CONTINUATION
          FC(i,0)=2.0*u(i,j,1)
          CF(i,1)=1.
#  endif
        enddo
        do k=1,N-1,+1    !--> irreversible
          do i=istrU,iend
            DC(i,k+1)=0.5625*(Hz(i  ,j,k+1)+Hz(i-1,j,k+1))
     &               -0.0625*(Hz(i+1,j,k+1)+Hz(i-2,j,k+1))

            cff=1./(2.*DC(i,k)+DC(i,k+1)*(2.-CF(i,k)))
            CF(i,k+1)=cff*DC(i,k)
            FC(i,k)=cff*( 3.*( DC(i,k  )*u(i,j,k+1)
     &                        +DC(i,k+1)*u(i,j,k  ))
     &                              -DC(i,k+1)*FC(i,k-1))
          enddo
        enddo               !--> discard DC, keep CF,FC
        do i=istrU,iend
#  if defined NEUMANN
          FC(i,N)=(3.*u(i,j,N)-FC(i,N-1))/(2.-CF(i,N))
#  elif defined LINEAR_CONTINUATION
          FC(i,N)=(2.*u(i,j,N)-FC(i,N-1))/(1.-CF(i,N))
#  endif
          DC(i,N)=0.        !<-- uppermost W*U flux 
        enddo
        do k=N-1,1,-1       !--> irreversible
          do i=istrU,iend
            FC(i,k)=FC(i,k)-CF(i,k+1)*FC(i,k+1)

            DC(i,k)=FC(i,k)*( 0.5625*(W(i  ,j,k)+W(i-1,j,k))
     &                       -0.0625*(W(i+1,j,k)+W(i-2,j,k)))

            ru(i,j,k+1)=ru(i,j,k+1) -DC(i,k+1)+DC(i,k)

            MVadv(i,j,k+1,1) = -DC(i,k+1)+DC(i,k)

          enddo
        enddo                       !--> discard CF,FC
        do i=istrU,iend
          ru(i,j,1)=ru(i,j,1) -DC(i,1)
          MVadv(i,j,1,1) =  -DC(i,1)
        enddo                          !--> discard DC

#  else
        do k=2,N-2
          do i=istrU,iend
            FC(i,k)=( 0.5625*(u(i,j,k  )+u(i,j,k+1))
     &               -0.0625*(u(i,j,k-1)+u(i,j,k+2)))
     &                       *( 0.5625*(W(i  ,j,k)+W(i-1,j,k))
     &                         -0.0625*(W(i+1,j,k)+W(i-2,j,k)))
          enddo
        enddo
        do i=istrU,iend
          FC(i,N)=0.
          FC(i,N-1)=( 0.5625*(u(i,j,N-1)+u(i,j,N))
     &                 -0.0625*(u(i,j,N-2)+u(i,j,N)))
     &                   *( 0.5625*(W(i  ,j,N-1)+W(i-1,j,N-1))
     &                     -0.0625*(W(i+1,j,N-1)+W(i-2,j,N-1)))
 
          FC(i,  1)=( 0.5625*(u(i,j,  1)+u(i,j,2))
     &                 -0.0625*(u(i,j,  1)+u(i,j,3)))
     &                       *( 0.5625*(W(i  ,j,1)+W(i-1,j,1))
     &                         -0.0625*(W(i+1,j,1)+W(i-2,j,1)))
          FC(i,0)=0.
        enddo

        do k=1,N
          do i=istrU,iend
            ru(i,j,k)=ru(i,j,k)-FC(i,k)+FC(i,k-1)
              MVadv(i,j,k,1) = -FC(i,k)+FC(i,k-1)
          enddo
        enddo               !--> discard FC
#  endif
 
 
        if (j.ge.jstrV) then
#  ifdef SPLINES
          do i=istr,iend
            DC(i,1)=0.5625*(Hz(i  ,j,1)+Hz(i,j-1,1))
     &             -0.0625*(Hz(i,j+1,1)+Hz(i,j-2,1))
#  if defined NEUMANN
            FC(i,0)=1.5*v(i,j,1)
            CF(i,1)=0.5
#  elif defined LINEAR_CONTINUATION
            FC(i,0)=2.0*v(i,j,1)
            CF(i,1)=1.
#  endif
          enddo
          do k=1,N-1,+1       !--> irreversible
            do i=istr,iend
              DC(i,k+1)=0.5625*(Hz(i  ,j,k+1)+Hz(i,j-1,k+1))
     &                 -0.0625*(Hz(i,j+1,k+1)+Hz(i,j-2,k+1))

              cff=1./(2.*DC(i,k)+DC(i,k+1)*(2.-CF(i,k)))
              CF(i,k+1)=cff*DC(i,k)
              FC(i,k)=cff*( 3.*( DC(i,k  )*v(i,j,k+1)
     &                          +DC(i,k+1)*v(i,j,k  ))
     &                                -DC(i,k+1)*FC(i,k-1))
            enddo
          enddo               !--> discard DC, keep CF,FC
          do i=istr,iend
#  if defined NEUMANN
            FC(i,N)=(3.*v(i,j,N)-FC(i,N-1))/(2.-CF(i,N))
#  elif defined LINEAR_CONTINUATION
            FC(i,N)=(2.*v(i,j,N)-FC(i,N-1))/(1.-CF(i,N))
#  endif
            DC(i,N)=0.        !<-- uppermost W*V flux
          enddo
          do k=N-1,1,-1       !--> irreversible
            do i=istr,iend
              FC(i,k)=FC(i,k)-CF(i,k+1)*FC(i,k+1)

              DC(i,k)=FC(i,k)*( 0.5625*(W(i,j  ,k)+W(i,j-1,k))
     &                         -0.0625*(W(i,j+1,k)+W(i,j-2,k)))

              rv(i,j,k+1)=rv(i,j,k+1) -DC(i,k+1)+DC(i,k)

                MVadv(i,j,k+1,2) = -DC(i,k+1)+DC(i,k)

            enddo
          enddo               !--> discard CF,FC

          do i=istr,iend
            rv(i,j,1)=rv(i,j,1) -DC(i,1)

              MVadv(i,j,1,2) = -DC(i,1)


          enddo                         !--> discard DC

#  else
          do k=2,N-2
            do i=istr,iend
              FC(i,k)=( 0.5625*(v(i,j,k )+v(i,j,k+1))
     &                 -0.0625*(v(i,j,k-1)+v(i,j,k+2)))
     &                         *( 0.5625*(W(i,j  ,k)+W(i,j-1,k))
     &                           -0.0625*(W(i,j+1,k)+W(i,j-2,k)))
            enddo
          enddo
          do i=istr,iend
            FC(i,N)=0.
            FC(i,N-1)=(  0.5625*(v(i,j,N-1)+v(i,j,N))
     &                  -0.0625*(v(i,j,N-2)+v(i,j,N)))
     &                    *( 0.5625*(W(i,j  ,N-1)+W(i,j-1,N-1))
     &                      -0.0625*(W(i,j+1,N-1)+W(i,j-2,N-1)))
 
            FC(i,  1)=(  0.5625*(v(i,j,  1)+v(i,j,2))
     &                  -0.0625*(v(i,j,  1)+v(i,j,3)))
     &                        *( 0.5625*(W(i,j  ,1)+W(i,j-1,1))
     &                          -0.0625*(W(i,j+1,1)+W(i,j-2,1)))
            FC(i,0)=0.
          enddo

          do k=1,N
            do i=istr,iend
              rv(i,j,k)=rv(i,j,k)-FC(i,k)+FC(i,k-1)

              MVadv(i,j,k,2) = -FC(i,k)+FC(i,k-1)

            enddo
          enddo
#  endif
        endif
# endif /* UV_ADV */




! ! 
! ! 
! ! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! ! !Update u,v with ru,rv
! ! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! ! 
! ! 
! !       cff=0.25*dt
! !         do i=istrU,iend
! !           DC(i,0)=cff*(pm(i,j)+pm(i-1,j))*(pn(i,j)+pn(i-1,j))
! !         enddo
! !         do k=1,N
! !           do i=istrU,iend
! !             u(i,j,k)=u(i,j,k)+DC(i,0)*ru(i,j,k)
! !           enddo
! !         enddo
! !         if (j.ge.jstrV) then
! !           do i=istr,iend
! !             DC(i,0)=cff*(pm(i,j)+pm(i,j-1))*(pn(i,j)+pn(i,j-1))
! !           enddo
! !           do k=1,N
! !             do i=istr,iend
! !               v(i,j,k)=v(i,j,k)+DC(i,0)*rv(i,j,k)
! !             enddo
! !           enddo
! !         endif
! ! 
! ! 
! ! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! ! 





          do i=istrU,iend
            do k=1,N
                u(i,j,k) =  u(i,j,k) * 0.5 *
     &                     (Hz(i,j,k)+Hz(i-1,j,k))

             if (j.ge.jstrV) then
                v(i,j,k) =  v(i,j,k) * 0.5 *
     &                     (Hz(i,j,k)+Hz(i,j-1,k))

             endif

            enddo
         enddo



!
! Start computation of the forcing terms for the 2D (barotropic mode)
! momentum equations: vertically integrate the just computed r.h.s
! "ru" and "rv". Also, if so prescribed, add in the difference
! between surface (wind) and bottom (drag) stresses. The computation
! of the 2D forcing terms will be finalized in "rhs2d" during the
! first barotropic time step, when the barotropically computed r.h.ss
! "rubar", "rvbar" will be subtracted from the vertically integrated
! (here) "rufrc", "rvfrc".
!


          do i=istrU,iend
           DC(i,0)=dt*0.25*(pm(i,j)+pm(i-1,j))*(pn(i,j)+pn(i-1,j))

            FC(i,N-1)=dt *2.*(Akv(i,j,N-1)+Akv(i-1,j,N-1))
     &                        /(  Hz(i,j,N  )+Hz(i-1,j,N  )
     &                          +Hz(i,j,N-1)+Hz(i-1,j,N-1))

            cff=1./(0.5*(Hz(i,j,N)+Hz(i-1,j,N))+FC(i,N-1))

            CF(i,N-1)=cff*FC(i,N-1)

!----------------------------------------------------------------------
            DC(i,N)=cff*( u(i,j,N) +DC(i,0)*ru(i,j,N)
     &                                      +dt*sustr(i,j))

!             DC(i,N)=cff*( u(i,j,N) *0.5*(Hz(i,j,N)+Hz(i-1,j,N))
!      &                 +DC(i,0)*ru(i,j,N)
!      &                                      +dt*sustr(i,j))
!----------------------------------------------------------------------

          enddo
          do k=N-1,2,-1      !--> forward elimination
            do i=istrU,iend
              FC(i,k-1)= dt*2.*(Akv(i,j,k-1)+Akv(i-1,j,k-1))
     &                          /(  Hz(i,j,k  )+Hz(i-1,j,k  )
     &                            +Hz(i,j,k-1)+Hz(i-1,j,k-1))

              cff=1./( 0.5*(Hz(i,j,k)+Hz(i-1,j,k)) +FC(i,k-1)
     &                                   +FC(i,k)*(1.-CF(i,k))
     &                                                       )
              CF(i,k-1)=cff*FC(i,k-1)

!----------------------------------------------------------------------
              DC(i,k)=cff*( u(i,j,k) +DC(i,0)*ru(i,j,k)
     &                                    +FC(i,k)*DC(i,k+1))

!               DC(i,k)=cff*( u(i,j,k) *0.5*(Hz(i,j,k)+Hz(i-1,j,k))
!      &                   +DC(i,0)*ru(i,j,k)
!      &                                    +FC(i,k)*DC(i,k+1))

!----------------------------------------------------------------------

            enddo
          enddo
          do i=istrU,iend

!----------------------------------------------------------------------
             DC(i,1)=(u(i,j,1) +DC(i,0)*ru(i,j,1)
     &                                +FC(i,1)*DC(i,2))
     &                   /( 0.5*(Hz(i,j,1)+Hz(i-1,j,1))
# ifdef NO_SLIP_BOTTOM
     &                    +dt * 0.5*(rd(i,j)+rd(i-1,j))
# endif
     &                         +FC(i,1)*(1.-CF(i,1)) )

! 
! 
!              DC(i,1)=(u(i,j,1)*0.5*(Hz(i,j,1)+Hz(i-1,j,1))
!      &                      +DC(i,0)*ru(i,j,1)
!      &                                +FC(i,1)*DC(i,2))
!      &                   /( 0.5*(Hz(i,j,1)+Hz(i-1,j,1))
! # ifdef NO_SLIP_BOTTOM
!      &                    +dt * 0.5*(rd(i,j)+rd(i-1,j))
! # endif
!      &                         +FC(i,1)*(1.-CF(i,1)) )

!----------------------------------------------------------------------

          enddo
          cff=1./dt
          do k=2,N,+1          !--> backsubstitution
            do i=istrU,iend
              DC(i,k)=DC(i,k) +CF(i,k-1)*DC(i,k-1)
!>
              FC(i,k-1)=cff*FC(i,k-1)*(DC(i,k)-DC(i,k-1))
            enddo
          enddo       !--> now FC is visc. flux
          do i=istrU,iend
            DC(i,0)=dm_u(i,j)*dn_u(i,j)
            ru(i,j,N)=ru(i,j,N) +DC(i,0)*(sustr(i,j)-FC(i,N-1))
            ru(i,j,1)=ru(i,j,1) +DC(i,0)*( FC(i,1)
     &                        -0.5*(rd(i-1,j)+rd(i,j))*DC(i,1) )



               MVmix(i,j,1,1)= DC(i,0)*( FC(i,1)
     &                        -0.5*(rd(i-1,j)+rd(i,j))*DC(i,1) )
               MVmix(i,j,N,1)= DC(i,0)*(sustr(i,j)-FC(i,N-1))






          enddo
          do k=N-1,2,-1
            do i=istrU,iend

              ru(i,j,k)=ru(i,j,k) +DC(i,0)*(FC(i,k)-FC(i,k-1))

              MVmix(i,j,k,1)=DC(i,0)*(FC(i,k)-FC(i,k-1))

            enddo
          enddo





          if (j.ge.jstrV) then

            do i=istr,iend
              DC(i,0)=dt*0.25*(pm(i,j)+pm(i,j-1))*(pn(i,j)+pn(i,j-1))

              FC(i,N-1)=dt *2.*(Akv(i,j,N-1)+Akv(i,j-1,N-1))
     &                          /(  Hz(i,j,N  )+Hz(i,j-1,N  )
     &                            +Hz(i,j,N-1)+Hz(i,j-1,N-1))

              cff=1./(0.5*(Hz(i,j,N)+Hz(i,j-1,N))+FC(i,N-1))

              CF(i,N-1)=cff*FC(i,N-1)
              DC(i,N)=cff*( v(i,j,N) +DC(i,0)*rv(i,j,N)
     &                                        +dt*svstr(i,j))
            enddo
            do k=N-1,2,-1      !--> forward elimination
              do i=istr,iend
                FC(i,k-1)= dt*2.*(Akv(i,j,k-1)+Akv(i,j-1,k-1))
     &                            /(  Hz(i,j,k  )+Hz(i,j-1,k  )
     &                              +Hz(i,j,k-1)+Hz(i,j-1,k-1))

                cff=1./( 0.5*(Hz(i,j,k)+Hz(i,j-1,k)) +FC(i,k-1)
     &                                    +FC(i,k)*(1.-CF(i,k))
     &                                                        )
                CF(i,k-1)=cff*FC(i,k-1)
                DC(i,k)=cff*( v(i,j,k) +DC(i,0)*rv(i,j,k)
     &                                      +FC(i,k)*DC(i,k+1))
              enddo
            enddo
            do i=istr,iend
               DC(i,1)=( v(i,j,1) +DC(i,0)*rv(i,j,1)
     &                                   +FC(i,1)*DC(i,2))
     &                      /( 0.5*(Hz(i,j,1)+Hz(i,j-1,1))
# ifdef NO_SLIP_BOTTOM
     &                         +dt*0.5*(rd(i,j)+rd(i,j-1))
# endif
     &                            +FC(i,1)*(1.-CF(i,1)) )
            enddo
            cff=1./dt
            do k=2,N,+1          !<-- backsubstitution
              do i=istr,iend
                DC(i,k)=DC(i,k) +CF(i,k-1)*DC(i,k-1)
!>
                FC(i,k-1)=cff*FC(i,k-1)*(DC(i,k)-DC(i,k-1))
              enddo
            enddo        !--> now FC is visc. flux

            do i=istr,iend
              DC(i,0)=dm_v(i,j)*dn_v(i,j)
              rv(i,j,N)=rv(i,j,N) +DC(i,0)*(svstr(i,j)-FC(i,N-1))
              rv(i,j,1)=rv(i,j,1) +DC(i,0)*( FC(i,1)
     &                          -0.5*(rd(i,j-1)+rd(i,j))*DC(i,1) )


                MVmix(i,j,1,2)= DC(i,0)*( FC(i,1)
     &                          -0.5*(rd(i,j-1)+rd(i,j))*DC(i,1) )
                MVmix(i,j,N,2)= DC(i,0)*(svstr(i,j)-FC(i,N-1))



            enddo
            do k=N-1,2,-1
              do i=istr,iend
                rv(i,j,k)=rv(i,j,k) +DC(i,0)*(FC(i,k)-FC(i,k-1))

                MVmix(i,j,k,2)=DC(i,0)*(FC(i,k)-FC(i,k-1))


              enddo
            enddo
          endif


# undef rd

      enddo      !<-- j




!---------------------------------------------------------------
! Divide all diagnostic terms by the cell volume Hz/(pm*pn).
! There after the unit of diag terms are :
! (unit of velocity) * s-1  =  m * s-2
!---------------------------------------------------------------

       do k=1,N
         do j=jstr,jend
           do i=istr,iend



            cff=0.5*(pm(i,j)+pm(i-1,j))
     &             *(pn(i,j)+pn(i-1,j))
     &             /(Hz(i,j,k)+Hz(i-1,j,k))
            
            MXadv(i,j,k,1)=MXadv(i,j,k,1)*cff
            MYadv(i,j,k,1)=MYadv(i,j,k,1)*cff
            MVadv(i,j,k,1)=MVadv(i,j,k,1)*cff
            MCor(i,j,k,1)=MCor(i,j,k,1)*cff
            MHdiff(i,j,k,1)=MHdiff(i,j,k,1)*cff
            MVmix(i,j,k,1)=MVmix(i,j,k,1)*cff
            MPrsgrd(i,j,k,1)=MPrsgrd(i,j,k,1)*cff


            cff=0.5*(pm(i,j)+pm(i,j-1))
     &             *(pn(i,j)+pn(i,j-1))
     &             /(Hz(i,j,k)+Hz(i,j-1,k))

            MXadv(i,j,k,2)=MXadv(i,j,k,2)*cff
            MYadv(i,j,k,2)=MYadv(i,j,k,2)*cff
            MVadv(i,j,k,2)=MVadv(i,j,k,2)*cff
            MCor(i,j,k,2)=MCor(i,j,k,2)*cff
            MHdiff(i,j,k,2)=MHdiff(i,j,k,2)*cff
            MVmix(i,j,k,2)=MVmix(i,j,k,2)*cff
            MPrsgrd(i,j,k,2)=MPrsgrd(i,j,k,2)*cff


           enddo
         enddo

       !write(*,*) 'the end..',k,N

       enddo



!---------------------------------------------------------------






      return
      end


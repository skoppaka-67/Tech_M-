import { Component, Output, EventEmitter, OnInit } from '@angular/core';
import { Router, NavigationEnd } from '@angular/router';
import { TranslateService } from '@ngx-translate/core';
import { environment } from '../../../../environments/environment';

@Component({
    selector: 'app-sidebar',
    templateUrl: './sidebar.component.html',
    styleUrls: ['./sidebar.component.scss']
})

export class SidebarComponent implements OnInit {
    isActive: boolean;
    collapsed: boolean;
    showMenu: string;
    showMenu1: string;
    showMenu2: string;
    showMenu3: string;
    pushRightClass: string;
    public resultStatus: string;
    link: any;
    userId: boolean;
    // userAdmin: boolean;
    login_data = false;

    //Dist - works changes from environment variable.
    ifTW: boolean;
    ifTWIM: boolean;
    ifProd: boolean;
    ifBSNF: boolean;
    ifMicrofocus: boolean;
    ifAS400: boolean;
    isNatural: boolean;
    isPLSQL: boolean;
    ifUPS: boolean;
    ifVBNET: boolean;

    @Output() collapsedEvent = new EventEmitter<boolean>();

    constructor(private translate: TranslateService, public router: Router) {
        this.translate.addLangs(['en', 'fr', 'ur', 'es', 'it', 'fa', 'de']);
        this.translate.setDefaultLang('en');
        const browserLang = this.translate.getBrowserLang();
        this.translate.use(browserLang.match(/en|fr|ur|es|it|fa|de/) ? browserLang : 'en');

        this.router.events.subscribe(val => {
            if (
                val instanceof NavigationEnd &&
                window.innerWidth <= 992 &&
                this.isToggled()
            ) {
                this.toggleSidebar();
            }
        });
    }
    ngOnInit() {
        this.isActive = false;
        this.collapsed = false;
        this.showMenu = '';
        this.showMenu1 = '';
        this.showMenu2 = '';
        this.pushRightClass = 'push-right';
        this.resultStatus = sessionStorage.getItem('resultStatus');


        //dist - works changes - depending on value:instance change below accordingly.
        const instance = environment.instance;
        if(instance=="microfocus"){
            this.ifTW=false;
            this.ifProd=false;
            this.ifMicrofocus=true;
            this.ifAS400=false;
            this.isNatural=false;
            this.isPLSQL=false;
            this.ifTWIM = false;
            this.ifUPS = false;
            this.ifBSNF=false;
            this.ifVBNET = false;
        }
        if(instance=="prod"){
            this.ifTW=false;
            this.ifProd=true;
            this.ifMicrofocus=false;
            this.ifAS400=false;
            this.isNatural=false;
            this.isPLSQL=false;
            this.ifTWIM = false;
            this.ifBSNF=false;
            this.ifUPS = false;
            this.ifVBNET = false;
        }
        if(instance=="tw"){
            this.ifTW=true;
            this.ifProd=false;
            this.ifMicrofocus=false;
            this.ifAS400=false;
            this.isNatural=false;
            this.isPLSQL=false;
            this.ifTWIM = false;
            this.ifBSNF=false;
            this.ifUPS = false;
            this.ifVBNET = false;
        }
        if(instance=="tw-im"){
            this.ifTW=false;
            this.ifProd=false;
            this.ifMicrofocus=false;
            this.ifAS400=false;
            this.isNatural=false;
            this.isPLSQL=false;
            this.ifTWIM = true;
            this.ifUPS = false;
            this.ifBSNF=false;
            this.ifVBNET = false;
        }
        if(instance=="as400"){
            this.ifTW=false;
            this.ifProd=false;
            this.ifMicrofocus=false;
            this.ifAS400=true;
            this.isNatural=false;
            this.isPLSQL=false;
            this.ifTWIM = false;
            this.ifBSNF=false;
            this.ifUPS = false;
            this.ifVBNET = false;
        }
        if(instance=="natural"){
            this.ifTW=false;
            this.ifProd=false;
            this.ifMicrofocus=false;
            this.ifAS400=false;
            this.isNatural=true;
            this.isPLSQL=false;
            this.ifTWIM = false;
            this.ifBSNF=false;
            this.ifUPS = false;
            this.ifVBNET = false;
        }
        if(instance=="plsql"){
            this.ifTW=false;
            this.ifProd=false;
            this.ifMicrofocus=false;
            this.ifAS400=false;
            this.isNatural=false;
            this.isPLSQL=true;
            this.ifTWIM = false;
            this.ifBSNF=false;
            this.ifUPS = false;
            this.ifVBNET = false;
        }
        if(instance=="bsnf"){
            this.ifTW=false;
            this.ifProd=false;
            this.ifMicrofocus=false;
            this.ifAS400=false;
            this.isNatural=false;
            this.isPLSQL=false;
            this.ifTWIM = false;
            this.ifBSNF=true;
            this.ifUPS = false;
            this.ifVBNET = false;
        }
        if(instance=="ups"){
            this.ifUPS = true;
            this.ifTW=false;
            this.ifProd=false;
            this.ifMicrofocus=false;
            this.ifAS400=false;
            this.isNatural=false;
            this.isPLSQL=false;
            this.ifTWIM = false;
            this.ifBSNF=false;
            this.ifVBNET = false;
        }
        if(instance=="vbnet"){
            this.ifVBNET = true;
            this.ifUPS = false;
            this.ifTW=false;
            this.ifProd=false;
            this.ifMicrofocus=false;
            this.ifAS400=false;
            this.isNatural=false;
            this.isPLSQL=false;
            this.ifTWIM = false;
            this.ifBSNF=false;
        }
        

       // console.log(this.resultStatus);
        const element = document.getElementById('exampleDiv');
        if (this.resultStatus === 'NODATA') {
            this.router.navigate(['/progress']);
        }
        const userLoggedIn = sessionStorage.getItem('id');
        if (userLoggedIn === 'admin') {
            this.userId = false;
        } else if (userLoggedIn === 'lcaasadmin') {
            this.userId = true;
            // this.userAdmin = true;
        } else if (userLoggedIn === 'demouser'){
            this.userId = false;
        }else if (userLoggedIn === 'geuser'){
            this.userId = false;
        }
        // else if (userLoggedIn === 'superuser') {
        //     this.userId = true;
        // }
}

    eventCalled() {
        this.isActive = !this.isActive;
    }

    addExpandClass(element: any) {
        if ((document.getElementById('expandMinimize') as HTMLElement).className === 'fa fa-plus') {
            (document.getElementById('expandMinimize') as HTMLElement).className = 'fa fa-minus';
        } else if ((document.getElementById('expandMinimize') as HTMLElement).className === 'fa fa-minus') {
            (document.getElementById('expandMinimize') as HTMLElement).className = 'fa fa-plus';
        }
        if (element === this.showMenu) {
            this.showMenu = '0';
        } else {
            this.showMenu = element;
        }
    }
    addExpandClass1(element1: any) {
        if ((document.getElementById('expandMinimize1') as HTMLElement).className === 'fa fa-minus') {
            (document.getElementById('expandMinimize1') as HTMLElement).className = 'fa fa-plus';
        } else if ((document.getElementById('expandMinimize1') as HTMLElement).className === 'fa fa-plus') {
            (document.getElementById('expandMinimize1') as HTMLElement).className = 'fa fa-minus';
        }
        if (element1 === this.showMenu1) {
            this.showMenu1 = '0';
        } else {
            this.showMenu1 = element1;
        }
    }

    addExpandClass2(element2: any) {
        if ((document.getElementById('expandMinimize2') as HTMLElement).className === 'fa fa-minus') {
            (document.getElementById('expandMinimize2') as HTMLElement).className = 'fa fa-plus';
        } else if ((document.getElementById('expandMinimize2') as HTMLElement).className === 'fa fa-plus') {
            (document.getElementById('expandMinimize2') as HTMLElement).className = 'fa fa-minus';
        }
        if (element2 === this.showMenu2) {
            this.showMenu2 = '0';
        } else {
            this.showMenu2 = element2;
        }
    }

    addExpandClass3(element3: any) {
        if ((document.getElementById('expandMinimize3') as HTMLElement).className === 'fa fa-minus') {
            (document.getElementById('expandMinimize3') as HTMLElement).className = 'fa fa-plus';
        } else if ((document.getElementById('expandMinimize3') as HTMLElement).className === 'fa fa-plus') {
            (document.getElementById('expandMinimize3') as HTMLElement).className = 'fa fa-minus';
        }
        if (element3 === this.showMenu3) {
            this.showMenu3 = '0';
        } else {
            this.showMenu3 = element3;
        }
    }

    toggleCollapsed() {
        if ((document.getElementById('collapseExpand') as HTMLElement).className === 'fa fa-fw fa-angle-double-left') {
            (document.getElementById('collapseExpand') as HTMLElement).className = 'fa fa-fw fa-angle-double-right';
        } else if ((document.getElementById('collapseExpand') as HTMLElement).className === 'fa fa-fw fa-angle-double-right') {
            (document.getElementById('collapseExpand') as HTMLElement).className = 'fa fa-fw fa-angle-double-left';
        }
        this.collapsed = !this.collapsed;
        this.collapsedEvent.emit(this.collapsed);
    }

    isToggled(): boolean {
        const dom: Element = document.querySelector('body');
        return dom.classList.contains(this.pushRightClass);
    }

    toggleSidebar() {
        const dom: any = document.querySelector('body');
        dom.classList.toggle(this.pushRightClass);
    }

    rltAndLtr() {
        const dom: any = document.querySelector('body');
        dom.classList.toggle('rtl');
    }

    changeLang(language: string) {
        this.translate.use(language);
    }

    onLoggedout() {
        localStorage.removeItem('isLoggedin');
    }
}

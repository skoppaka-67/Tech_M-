import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbCarouselModule, NgbAlertModule } from '@ng-bootstrap/ng-bootstrap';
import { BrowserModule } from '@angular/platform-browser';

import { ChartsModule as Ng2Charts } from 'ng2-charts';
import {DataTablesModule } from 'angular-datatables';


import { DashboardRoutingModule } from './dashboard-routing.module';
import { DashboardComponent } from './dashboard.component';
import { PageHeaderModule } from './../../shared';
import {
    TimelineComponent,
    NotificationComponent,
    ChatComponent,
} from './components';
import { StatModule } from '../../shared';




@NgModule({
    imports: [
        CommonModule,
        NgbCarouselModule,
        NgbAlertModule,
        DashboardRoutingModule,
        StatModule,
        Ng2Charts,
        DataTablesModule
    ],
    declarations: [
        DashboardComponent,
        TimelineComponent,
        NotificationComponent,
        ChatComponent
    ]
})
export class DashboardModule {}

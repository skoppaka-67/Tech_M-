import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { DropImpactAppRoutingModule } from './dropimpact-application-routing.module';
import { DropImpactAppComponent } from './dropimpact-application.component';
import { PageHeaderModule } from '../../shared';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';


@NgModule({
    imports: [CommonModule, DropImpactAppRoutingModule, PageHeaderModule,DataTablesModule, NgbModule],
    declarations: [DropImpactAppComponent]
})
export class DropImpactAppModule {}

import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { OrphanAppRoutingModule } from './orphan-application-routing.module';
import { OrphanAppComponent } from './orphan-application.component';
import { PageHeaderModule } from '../../shared';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';


@NgModule({
    imports: [CommonModule, OrphanAppRoutingModule, PageHeaderModule,DataTablesModule, NgbModule],
    declarations: [OrphanAppComponent]
})
export class OrphanAppModule {}

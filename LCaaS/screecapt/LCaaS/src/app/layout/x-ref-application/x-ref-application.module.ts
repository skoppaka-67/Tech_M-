import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { XrefApplicaitonRoutingModule } from './x-ref-routing.module';
import { XrefApplicationComponent } from './x-ref-application.component';
import { PageHeaderModule } from '../../shared';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

@NgModule({
    imports: [CommonModule, XrefApplicaitonRoutingModule, PageHeaderModule, DataTablesModule, NgbModule],
    declarations: [XrefApplicationComponent]
})
export class XrefApplicationModule {}

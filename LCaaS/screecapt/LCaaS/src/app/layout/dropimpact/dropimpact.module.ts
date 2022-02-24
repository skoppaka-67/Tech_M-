import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { DropImpactRoutingModule } from './dropimpact-routing.module';
import { DropImpactComponent } from './dropimpact.component';
import { PageHeaderModule } from '../../shared';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';


@NgModule({
    imports: [CommonModule, DropImpactRoutingModule, PageHeaderModule,DataTablesModule, NgbModule],
    declarations: [DropImpactComponent]
})
export class DropImpactModule {}

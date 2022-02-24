import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { ImpactRoutingModule } from './impact-routing.module';
import { ImpactComponent } from './impact.component';
import { PageHeaderModule } from '../../shared';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

@NgModule({
    imports: [CommonModule, ImpactRoutingModule, PageHeaderModule, DataTablesModule, NgbModule],
    declarations: [ImpactComponent]
})
export class ImpactModule {}

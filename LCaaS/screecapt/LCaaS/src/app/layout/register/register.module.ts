import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RegisterRoutingModule } from './register-routing.module';
import { RegisterComponent } from './register.component';
import { PageHeaderModule } from '../../shared';
import { FormsModule } from '@angular/forms';
 import { ReactiveFormsModule } from '@angular/forms';

@NgModule({
    imports: [CommonModule,
        RegisterRoutingModule,
        PageHeaderModule,
        FormsModule,
        ReactiveFormsModule
],
    declarations: [RegisterComponent],
    schemas: [],
    providers: [],
    bootstrap:    [RegisterComponent]
})
export class RegisterModule {}
